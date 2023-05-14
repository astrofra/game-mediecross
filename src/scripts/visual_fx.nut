/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	VisualFX
{
	scene			=	0
	ui				=	0

	fx				=	0
	current_fx		=	0

	// Helper function to get a random hit FX from the available UI clips.
	function	GetHitFXIndex()
	{
		local	indexes = [0, 1]
		return indexes[Rand(0, indexes.len())]
	}

	// Helper function to get a random land FX from the available UI clips.
	function	GetLandFXIndex()
	{
		local	indexes = [2, 3]
		return indexes[Rand(0, indexes.len())]
	}

	// Display a visual FX from its index.
	function	ShowFX(index, world_pos, scale = 1.0)
	{
		// Limit to one visual FX at once.
		if	((current_fx != 0) && !WindowIsCommandListDone(current_fx))
			return

		scale *= 0.4	// Global scale adjustment for all FXs.

		// Get the FX screen position from the provided 3d world position.
		local	screen_pos = CameraWorldToScene2d(SceneGetCurrentCamera(scene), world_pos, ui)

		// Initialize the FX window position and asynch command list.
		current_fx = fx[index]

		WindowSetPosition(current_fx, screen_pos.x - (100 + Rand(-50, 50)) * scale, screen_pos.y - (60 + Rand(-50, 50)) * scale)
		WindowSetOpacity(current_fx, 1)
		WindowSetCommandList(current_fx, "toangle 0,0 + toscale 0,0,0; toscale 0.05," + scale * 2 + "," + scale * 2 + "; nop 0.2; toalpha 0.15,0;")
 	}

	constructor(_scene)
	{
		// Retrieve the provided scene UI component.
		scene = _scene
		ui = SceneGetUI(_scene)

		// Create an empty array to store the FX windows.
		fx = []

		// For each visual FX TGA picture in the UI directory...
		for	(local n = 0; n < 5; ++n)
		{
			// Create a new bitmap window for the FX.
			local	window = UIAddBitmapWindow(ui, -1, "ui/sound_fx_" + n + ".tga", 0, 0, 256, 256)

			// Center the window pivot and make it fully transparent.
			WindowSetPivot(window, 128, 128)
			WindowSetOpacity(window, 0)
			SpriteRenderSetup(window, g_factory)

			// Append the newly created window to our array.
			fx.append(window)
		}
	}
}
