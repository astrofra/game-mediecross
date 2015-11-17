/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	EndScreen
{
	ui			=	0
	is_done		=	false

	function	OnUpdate(scene)
	{
		// Update the current state.
		is_done = UIIsCommandListDone(ui)

		// If the command list is done, return.
		if	(is_done)
			return

		// Check for the space key press.
		if	(DeviceIsKeyDown(GetKeyboardDevice(), KeySpace))
		{
			// Start an immediate fade, the command list will now last 2 seconds only.
			UISetCommandList(ui, "globalfade 2, 1;")
		}
	}

	function	OnSetup(scene)
	{
		// Grab UI controller.
		ui = SceneGetUI(scene)

		// Set current global fade effect to full opacity.
		UISetGlobalFadeEffect(ui, 1)

		try
		{
			// Create a text window to display the congratulation message.
			local	window = CreateTextWindow(ui, 900, 180, 1024, 256)
			TextSetText(window[1], "~~Color(230, 200, 80, 255)Congratulations!\n~~Size(32)~~Color(100, 80, 160, 255)Knight Gyslain made it to the towers of the 5th axis.\n...\nAs the wind blows through the visor of his helmet\nGyslain shivers at the thought of all the stairs\nhe will climb in a next TIGS contest entry.")

			// Create a text window to display the player final score (stored in the global g_score).
			local	score_window = CreateTextWindow(ui, 200, 860, 1024, 128)
			TextSetText(score_window[1], format("Your Score %d", g_score.tointeger()))
		}
		catch (e) {}

		// Set the UI global command list to fade in, pause for 60 seconds, then fade out.
		UISetCommandList(ui, "globalfade 0, 1; globalfade 2, 0; nop 60; globalfade 2, 1;")

		// Start the gong mood SFX.
		MixerSoundStart(g_mixer, EngineLoadSound(g_engine, "sfx/sfx_gong_mood.ogg"))

		/*
			Prevent knight controls.

			To do that, find the 'Knight/Controller' item, and access its script instance
			of the 'CharacterControl' class.
		*/
		ItemGetScriptInstanceFromClass(SceneFindItem(scene, "Knight/Controller"), "CharacterControl").stop_controls = true
	}
}
