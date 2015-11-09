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




nml_reader = NmlReader()
nml_reader.LoadingXmlFile("in/level_0.nms")


in_root =  nml_reader.main_node.GetChild("Scene")
in_items = in_root.GetChilds("Items")

for in_item in in_items:
	mobject = in_item.GetChilds("MObject")
	print(mobject)
