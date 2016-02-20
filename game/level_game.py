import gs
import gs.plus.render as render
import gs.plus.input as input
import gs.plus.scene as scene
import gs.plus.clock as clock
import asyncio

import globals
from character_control import CharacterControl

scn = None
dt_sec = 1.0 / 60.0
player = None
player_follower = None


def setup():
	global scn, player, player_follower
	scn = scene.new_scene()
	scn.Load('@assets/3d/level_' + str(globals.current_level) + '.scn', gs.SceneLoadContext(render.get_render_system()))

	while not scn.IsReady():
		scene.update_scene(scn, 0.0)
		yield from asyncio.sleep(1)

	player = CharacterControl(scn)
	player_follower = scn.GetNode('player_follower', None)


def follow_player():
	global dt_sec
	if player_follower is not None:
		follower_pos = player_follower.GetTransform().GetPosition()
		pos_delta = player.transform.GetPosition() - follower_pos
		pos_delta *= dt_sec
		player_follower.GetTransform().SetPosition(follower_pos + pos_delta)


def exit():
	pass


def update():
	global dt_sec
	dt_sec = clock.update()
	scene.update_scene(scn, dt_sec)
	player.update(dt_sec)
	follow_player()


def draw():
	pass
