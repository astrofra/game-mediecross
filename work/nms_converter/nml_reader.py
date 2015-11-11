import gs
import gs.plus.render as render
import gs.plus.camera as camera
import gs.plus.input as input
import gs.plus.scene as scene
import gs.plus.clock as clock

import os

class NmlNode():
	def __init__(self):
		self.m_Data = ""
		self.m_Name = ""

		self.list_child = []

	def GetChild(self, name_child):
		for child in self.list_child:
			if child.m_Name == name_child:
				return child

	def GetChilds(self, name_child):
		temp_list = []

		for child in self.list_child:
			if child.m_Name == name_child:
				temp_list.append(child)

		return temp_list

	def LoadNml(self, _FormatFile, _ReadChar, _RootTreeXml, _CurrentDepth=0):

		l_Error = False
		l_CurrentChar = ""

		l_FinishinthisTree = False

		l_NewTree = None

		if len(_FormatFile) <= _ReadChar:
			return _ReadChar

		l_CurrentChar = _FormatFile[_ReadChar]
		_ReadChar += 1

		while _ReadChar < len(_FormatFile) and l_Error == False and l_FinishinthisTree == False:

			# find the next letter
			while l_CurrentChar == '<':			
				l_CurrentChar = _FormatFile[_ReadChar]
				_ReadChar += 1

			# end of this root tree
			if l_CurrentChar == '>':
				l_FinishinthisTree = True
			else:		# another tree began

				# if not the end of the file
				if _ReadChar < len(_FormatFile):

					l_NewTree = NmlNode()
					l_NewTree.m_Name = ""

					while l_CurrentChar != '>' and l_CurrentChar != '=' and _ReadChar < len(_FormatFile):	# read name

						l_NewTree.m_Name = l_NewTree.m_Name + l_CurrentChar

						l_CurrentChar = _FormatFile[_ReadChar]
						_ReadChar += 1				


					# find the next letter
					while l_CurrentChar == '=':
						l_CurrentChar = _FormatFile[_ReadChar]
						_ReadChar += 1				

					# another tree
					if l_CurrentChar == '<':	
						_ReadChar = self.LoadNml(_FormatFile, _ReadChar, l_NewTree, _CurrentDepth+1)

					else:		# find the data

						l_NewTree.m_Data = ""

						while l_CurrentChar != '>' and _ReadChar < len(_FormatFile):	# read Data

							l_NewTree.m_Data = l_NewTree.m_Data + l_CurrentChar

							l_CurrentChar = _FormatFile[_ReadChar]
							_ReadChar += 1				


						# to go one step of the >
						if _ReadChar <  len(_FormatFile):
							l_CurrentChar = _FormatFile[_ReadChar]
							_ReadChar += 1				


					# put in the root tree
					_RootTreeXml.list_child.append(l_NewTree)

		return _ReadChar


class NmlReader():

	def FormatFileXml(self, f):

		l_FormatFile = ""

		l_TempText = f.read()
		read_char = 0
		l_CurrentChar = l_TempText[read_char]
		read_char += 1

		while l_CurrentChar != 0 and read_char < len(l_TempText):

			if l_CurrentChar != '\n' and l_CurrentChar != '\t' :
				l_FormatFile = l_FormatFile + l_CurrentChar

			l_CurrentChar =  l_TempText[read_char]
			read_char += 1

		return l_FormatFile

	def LoadingXmlFile(self, _NameFile):
		f = open(_NameFile, 'r')
		format_file = self.FormatFileXml(f)

		self.main_node = NmlNode()
		self.main_node.LoadNml(format_file, 0, self.main_node)


def nmlParseVector(_nml_node):
	return gs.Vector3(float(_nml_node.GetChild("X").m_Data), float(_nml_node.GetChild("Y").m_Data), float(_nml_node.GetChild("Z").m_Data))


def cleanNMLString(_str):
	return _str.replace('"', '')

# Convertion routine
# - Loads manually each relevant node from a NML file
# - Recreate each node into the scengraph
# - Saves the resulting scene into a new file (Json or XML)

root_in = "in"
root_out = "out"
root_assets = "../../game/"
folder_assets = "assets/3d/"

gs.GetFilesystem().Mount(gs.StdFileDriver("../../game/pkg.core"), "@core")
gs.GetFilesystem().Mount(gs.StdFileDriver(root_assets), "@assets")
gs.GetFilesystem().Mount(gs.StdFileDriver(root_out), "@out")

# Init the engine
render.init(640, 400, "../pkg.core")


def convert_folder(folder_path):
	scn = None

	nml_reader = NmlReader()

	for in_file in os.listdir(folder_path):

		if os.path.isdir(os.path.join(folder_path, in_file)):
			convert_folder(os.path.join(folder_path, in_file))
		else:
			if in_file.find(".nms") > -1:
				# Found a NMS file, creates a new scene
				scn = scene.new_scene()

				print("Reading file ", os.path.join(folder_path, in_file))
				nml_reader.LoadingXmlFile(os.path.join(folder_path, in_file))

				in_root =  nml_reader.main_node.GetChild("Scene")
				in_items = in_root.GetChilds("Items")

				for in_item in in_items:
					mobjects = in_item.GetChilds("MObject")
					for mobject in mobjects:

						mitem = mobject.GetChild("MItem")
						object = mobject.GetChild("Object")
						item = object.GetChild("Item")

						# get item name
						id = mitem.GetChild("Id")
						item_name = cleanNMLString(id.m_Data)

						# get item geometry
						geometry_filename = None
						if object is not None:
							geometry = object.GetChild("Geometry")
							if geometry is not None:
								geometry_filename = geometry.m_Data
								geometry_filename = cleanNMLString(geometry_filename)
								if geometry_filename.find("/") > -1:
									geometry_filename = geometry_filename.split("/")[-1]
								geometry_filename = geometry_filename.replace(".nmg", ".geo")

						# transformation
						rotation = item.GetChild("Rotation")
						if rotation is None:
							rotation = gs.Vector3()
						else:
							rotation = nmlParseVector(rotation)

						position = item.GetChild("Position")
						if position is None:
							position = gs.Vector3()
						else:
							position = nmlParseVector(position)

						scale = item.GetChild("Scale")
						if scale is None:
							scale = gs.Vector3(1, 1, 1)
						else:
							scale = nmlParseVector(scale)

						rotation_order = item.GetChild("RotationOrder")
						if rotation_order is None:
							rotation_order = "YXZ"
						else:
							rotation_order = rotation_order.m_Data

						# print(item_name, geometry_filename, rotation_order)

						new_node = None

						if geometry_filename is not None and geometry_filename != '':
							new_node = scene.add_geometry(scn, os.path.join(folder_assets, geometry_filename))

						if new_node is not None:
							new_node.SetName(item_name)
							new_node.GetComponentsWithAspect("Transform")[0].SetPosition(position)
							new_node.GetComponentsWithAspect("Transform")[0].SetRotation(rotation)
							new_node.GetComponentsWithAspect("Transform")[0].SetScale(scale)

				env_global = gs.Environment()
				scn.AddComponent(env_global)

				scn.Commit()
				scn.WaitCommit()

				# Creates the output folder
				folder_out = folder_path.replace(root_in + '\\', '')
				folder_out = folder_out.replace(root_in + '/', '')
				folder_out = folder_out.replace(root_in, '')

				if folder_out !='' and not os.path.exists(os.path.join(root_out, folder_out)):
					os.makedirs(os.path.join(root_out, folder_out), exist_ok=True)

				out_file = os.path.join("@out", folder_out, in_file.replace(".nms", ".scn"))
				print('saving to ', out_file)
				scn.Save(out_file, gs.SceneSaveContext(render.get_render_system()))

convert_folder(root_in)
