# Character Control

import gs


class CharacterControl:

	def __init__(self, parent_scene):
		self.scene = parent_scene
		self.node = gs.Node()
		self.transform = gs.Transform()
		self.node.AddComponent(self.transform)
		self.scene.AddNode(self.node)

	def update(self, dt):
		self.transform.SetPosition(self.transform.GetPosition() + gs.Vector3(0, 0, dt))
		print(self.transform.GetPosition().z)