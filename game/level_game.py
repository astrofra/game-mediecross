import gs
import gs.plus.render as render
import gs.plus.input as input
import gs.plus.scene as scene
import gs.plus.clock as clock

import globals

scn = None
dt_sec = 1.0 / 60.0

def setup():
	global scn
	scn = scene.new_scene()
	scn.Load('@assets/3d/level_' + str(globals.current_level) + '.scn', gs.SceneLoadContext(render.get_render_system()))

def exit():
	pass

def update():
	global dt_sec
	dt_sec = clock.update()
	scene.update_scene(scn, dt_sec)

def draw():
	pass
