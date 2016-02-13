import gs
import gs.plus
import gs.plus.render as render
import gs.plus.input as input
import gs.plus.clock as clock

import globals
import level_title
import os
import sys


globals.prev_scene_fade = globals.current_scene = level_title
# globals.prev_scene_fade = globals.current_scene = ecran_eggs


show_help = False

fade_percent = 1
fade_speed = 1.0
state_fade_in = 1
state_ready = 2
state_fade_out = 3

state = state_fade_out

if getattr(sys, 'frozen', False):
	app_path = os.path.dirname(sys.executable)
else:
	app_path = os.path.dirname(os.path.realpath(__file__))

# gs.plus.create_workers()
gs.LoadPlugins(gs.get_default_plugins_path())
render.init(1280, 720, os.path.normcase(os.path.realpath(os.path.join(app_path, "pkg.core"))))

# provide access to the assets folder
data_path = os.path.normcase(os.path.realpath(app_path))
gs.GetFilesystem().Mount(gs.StdFileDriver(data_path))

render.set_blend_mode2d(render.BlendAlpha)

globals.current_scene.setup()


def fade_between_scene():
	global state, fade_percent
	if globals.prev_scene_fade != globals.current_scene:
		# transition to the new scene
		state = state_fade_in

	# launch the fade in
	if state == state_fade_in:
		fade_percent += fade_speed * globals.dt_sec
		if fade_percent > 1:
			fade_percent = 1
			state = state_fade_out
			globals.current_scene.setup()
			globals.prev_scene_fade = globals.current_scene

	#launch fade out with the new scene
	if state == state_fade_out:
		fade_percent -= fade_speed * globals.dt_sec
		if fade_percent < 0:
			fade_percent = 0
			state = state_ready

	if fade_percent > 0:
		color = gs.Color(0, 0, 0, fade_percent)
		size = render.get_renderer().GetCurrentOutputWindow().GetSize()
		render.triangle2d(0, 0, size.x, size.y, size.x, 0, color, color, color)
		render.triangle2d(0, 0, 0, size.y, size.x, size.y, color, color, color)


while not input.key_press(gs.InputDevice.KeyEscape):
	globals.dt_sec = clock.update()

	render.clear(gs.Color.Black)

	if state == state_ready or state == state_fade_out:
		if globals.current_scene is not None:
			globals.current_scene.draw()
			globals.current_scene.update()
	else:
		if globals.prev_scene_fade is not None:
			globals.prev_scene_fade.draw()
			globals.prev_scene_fade.update()

	fade_between_scene()

	render.flip()