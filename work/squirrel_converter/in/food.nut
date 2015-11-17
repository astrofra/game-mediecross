/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	Food
{
	food_item		=	0
	food_mesh		=	0

	ui				=	0
	fx_window		=	0
	fx_y_offset		=	0
	fx_pos			=	0

	function	Eat()
	{
		// Disable trigger.
		ItemActivate(SceneFindItemChild(g_scene, food_item, "Food Trigger"), false)

		// Replace the current 'meat and bone' mesh by the 'bone only' mesh.
		ObjectSetGeometry(food_mesh, EngineLoadGeometry(g_engine, "meshes/food_empty_0.nmg"))

		// Switch to physics.
		ItemSetPhysicMode(food_item, PhysicModeDynamic)
		SceneSetupItem(g_scene, food_item)

		// Drop in the air.
		ItemApplyLinearImpulse(food_item, Vector(0, 12, 0))
		ItemApplyTorque(food_item, Vector(64, 0, 8))

		// Create an FX window.
		fx_window = CreateTextWindow(ui, 0, 0, 256, 96, 3)
		TextSetText(fx_window[1], "+0.5s")

		// Store the eat position to display the bonus at.
		fx_pos = ItemGetWorldPosition(food_item)

		// Start the scroll up command list.
		WindowSetCommandList(fx_window[0], "toalpha 0, 1; nop 0.75; toalpha 0.25, 0;")
	}

	function	OnUpdate(item)
	{
		if	(fx_window == 0)
			return

		// Keep the window in the original pickup place.
		local		p = CameraWorldToScene2d(SceneGetCurrentCamera(g_scene), fx_pos, ui)
		WindowSetPosition(fx_window[0], p.x, p.y - fx_y_offset)

		// Increase the Y offset.
		fx_y_offset += g_dt_frame * 128.0

		// Cleanup the pickup window if its command list is done.
		if	(WindowIsCommandListDone(fx_window[0]))
		{
			UIDeleteWindow(ui, fx_window[0])
			fx_window = 0
		}
	}

	function	OnSetup(item)
	{
		ui = SceneGetUI(g_scene)

		// Stock this item to be able to call the Eat() function with no parameters to pass.
		food_item = item

		// Get this item child with the visual mesh and store it.
		food_mesh = ItemCastToObject(SceneFindItemChild(g_scene, item, "Food_mesh"))
	}
}
