/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/


// HELPER FUNCTIONS START -----------------------------------------------------------------

//-----------------------------------------------------------------------------------------
function	CreateTextWindow(ui, x, y, w, h, scale = 1)
{
	w /= scale; h /= scale

	// Create a new window and a static text widget.
	local		window = UIAddWindow(ui, -1, x, y, w, h),
				widget = UIAddStaticTextWidget(ui, -1, "", "brokenscript")

	// Center window pivot.
	WindowSetPivot(window, w / 2, h / 2)

	// Set the window base widget.
	WindowSetBaseWidget(window, widget)

	// Adjust scale.
	WindowSetScale(window, scale, scale)

	// Setup text properties.
	TextSetSize(widget, 80 / scale)
	TextSetColor(widget, 255, 255, 220, 255)
	TextSetAlignment(widget, TextAlignCenter)

	WindowRenderSetup(window, g_factory)

	// Return an array containing the window/widget pair.
	return [window, widget]
}
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
local		level_name =
[
	"Knights'n'Barrels",
	"Rolling Bumper",
	"Jumpin' Knight Path",
	"Red means Dead",
	"Shine, Oh my Helmet",
	"Through the Barrels",
	"Square and Unfair"
]

// Helper function to create the level title message.
function	SetupLevelMessage(text)
{
	// This helper function set the level title text on a provided text widget.
	TextSetText(text, format("~~Size(64)~~Color(196, 160, 255, 255)Chapter %d\n~~Size(96)~~Color(250, 220, 220, 255)~ %s ~", g_current_level + 1, level_name[g_current_level]))
}
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
function	SwitchToCamera(scene, camera)
{
	/*
		Move the vignette effect object to the new camera we are switching to.
		This is done by changing the 'vignette' item parent to the new camera.
	*/
	ItemSetParent(SceneFindItem(scene, "vignette"), CameraGetItem(camera))

	// Switch scene to this camera.
	SceneSetCurrentCamera(scene, camera)
}

// HELPER FUNCTIONS END -------------------------------------------------------------------



//-----------------------------------------------------------------------------------------
/*
	The scene level class.

	This class uses a coroutine defined below this definition to reduce the work
	required to handle all of the level states.
*/
class	SceneLevel
{
	state				=	0
	level_logic			=	0

	function	OnUpdate(scene)
	{
		/*
			On each update we resume the coroutine from the last point it suspended from,
			the coroutine returns the current game state when suspending so we update it
			here.
		*/
		state = level_logic.wakeup()
	}

	function	OnSetup(scene)
	{
		// [EJ] Fix to allow testing a level from its scene directly.
		try
		{
			ProjectGetUIFont(g_project, "garamond")
			ProjectGetUIFont(g_project, "brokenscript")
		}
		catch(e)
		{
			ProjectLoadUIFont(g_project, "ui/garamond.ttf")
			ProjectLoadUIFont(g_project, "ui/brokenscript.ttf")
		}

		/*
			Start the level logic as a coroutine.

			A coroutine can suspend its execution by calling the suspend() function and
			be resumed from this point later on. This is a very convenient way to avoid
			using a large state machine.

			The code for this coroutine is in the LevelLogic function defined below.
		*/
		level_logic = newthread(LevelLogic)

		/*
			Spawn the coroutine.
			Store the return value of the coroutine as the current level state.
		*/
		state = level_logic.call()
	}
}
//-----------------------------------------------------------------------------------------



/*
	The level logic coroutine.

	Remember that this coroutine suspends (by calling suspend()) and resumes on each
	update from where it left (when called from the scene OnUpdate script callback).
	This way all variables are kept in context and we do not need to store anything in
	the global space or in a structure.
*/
function	LevelLogic()
{
	//-------------------------------------------------------------------------------------
	// Prepare everything we will need to do our work.
	//-------------------------------------------------------------------------------------

	// This is a debug flag to skip the level introduction.
	local		quickstart = false

	// Load the intro and game over SFX.
	local		sfx_intro = EngineLoadSound(g_engine, "sfx/sfx_fanfare_intro.ogg"),
				sfx_game_over = EngineLoadSound(g_engine, "sfx/sfx_game_over.ogg")

	// Grab the knight controller and its script instance of the 'CharacterControl' class.
	local		knight_item = SceneFindItem(g_scene, "knight/Controller"),
				knight_script = ItemGetScriptInstanceFromClass(knight_item, "CharacterControl")

	// Prevent the knight from moving.
	knight_script.stop_controls = true

	// Grab scene UI.
	local		ui = SceneGetUI(g_scene)

	// Set the global fade to fully opaque.
	UISetGlobalFadeEffect(ui, 1)

	// Create the life icon.
	local		life_icon_window = UIAddBitmapWindow(ui, -1, "ui/life.png", 960, 40, 96, 128)
	WindowSetOpacity(life_icon_window, 0)

	// Create the life count icon.
	local		life_count_window = CreateTextWindow(ui, 110, 100, 96, 96, 2)

	/*
		Parent the life text window to the life icon window.
		This way it will inherit all its properties including its opacity and scale
		as they are modified through a command list.
	*/
	WindowSetParent(life_count_window[0], life_icon_window)
	TextSetText(life_count_window[1], (g_retry_count + 1).tostring())

	// Prepare the 'Ready?' UI window.
	local		osd_ready = UIAddBitmapWindow(ui, -1, "ui/osd_ready.tga", 640, 480, 256, 128)
	WindowSetPivot(osd_ready, 128, 64)
	WindowSetOpacity(osd_ready, 0)

	// Prepare the 'Run!' UI window.
	local		osd_run = UIAddBitmapWindow(ui, -1, "ui/osd_run.tga", 640, 480, 256, 128)
	WindowSetPivot(osd_run, 128, 64)
	WindowSetOpacity(osd_run, 0)

	// Create the time & score UI elements.
	local		time_window = CreateTextWindow(ui, 640, 100, 512, 128, 2),
				score_window = CreateTextWindow(ui, 640, 160, 512, 128, 2),
				message_window = CreateTextWindow(ui, 640, 800, 1024, 256)

	TextSetColor(time_window[1], 255, 255, 220, 255)
	TextSetSize(score_window[1], 48 / 2)

	// Setup level message.
	SetupLevelMessage(message_window[1])
	WindowSetCommandList(message_window[0], "nop 3; toalpha 1, 0;")

	/*
		Switch to the start camera (this camera is parented to the knight controller and
		uses a builtin script to rotate around it, cf. the knight_controller.nms scene).
	*/
	SwitchToCamera(g_scene, ItemCastToCamera(SceneFindItem(g_scene, "Finish Camera")))

	UIRenderSetup(ui, g_factory)

	/*
		At this point we suspend execution.

		This function was not suspended since its first call, so we will exit through this
		suspend call to SceneLevel::OnSetup() right after the call() call that spawned
		this coroutine.

		The next call to this coroutine will resume right after this suspend and will be
		done during the next display update throught the SceneLevel::OnUpdate() call to
		wakeup() (line 95).
	*/
	suspend("Game")

	//-------------------------------------------------------------------------------------


	//-------------------------------------------------------------------------------------
	// Display the level name and rotate around the knight character.
	//-------------------------------------------------------------------------------------

	// Start the music!
	MixerSoundStart(g_mixer, sfx_intro)

	// Program the UI to fade-in in 1 second, pause for 3 seconds then fade out in 0.15 seconds.
	UISetCommandList(ui, "globalfade 1, 0; nop 3; globalfade 0.15, 1;")

	// If quickstarted, do not pause.
	if	(!quickstart)
		// Otherwise, as long as the UI command list is not done, we wait...
		while (!UIIsCommandListDone(ui))
			suspend("Game")

	//-------------------------------------------------------------------------------------


	//-------------------------------------------------------------------------------------
	// Switch to the game camera, display the 'Ready?', 'Go!' UI elements.
	//-------------------------------------------------------------------------------------

	// Switch to the game camera.
	SwitchToCamera(g_scene, ItemCastToCamera(SceneFindItem(g_scene, "render_camera")))

	// Fade in the life count window.
	WindowSetCommandList(life_icon_window, "toalpha 0, 0; toalpha 0.25, 1;")

	// Global UI fade-in in 0.15 seconds.
	UISetCommandList(ui, "globalfade 0.15, 0;")

	if	(!quickstart)
		// Wait for the command list end.
		while (!UIIsCommandListDone(ui))
			suspend("Game")

	// Program the 'Ready?' UI element.
	WindowSetCommandList(osd_ready, "nop 0.5; toalpha 0, 1 + toscale 0, 3, 3; toscale 2, 2, 2; toalpha 0.25, 0; nop 0.25;")

	if	(!quickstart)
		// Wait for the command list end.
		while (!WindowIsCommandListDone(osd_ready))
			suspend("Game")

	// Program the 'Run!' UI element...
	WindowSetCommandList(osd_run, "toalpha 0, 1 + toscale 0, 3, 3; nop 0.5; toalpha 0.2, 0;")

	// Enable knight controls.
	knight_script.stop_controls = false

	// Fade in the score and time UI windows.
	WindowSetCommandList(time_window[0], "toalpha 0, 0; toalpha 0.25, 1;")
	WindowSetCommandList(score_window[0], "toalpha 0, 0; toalpha 0.25, 1;")

	//-------------------------------------------------------------------------------------


	//-------------------------------------------------------------------------------------
	// The game loop.
	//-------------------------------------------------------------------------------------

	// You got 40 seconds to run max.
	local		time_left = 40.0

	/*
		We will use a simple system to limit UI update.

		Normally the fast performance writer should be used.
		But for the sake of simplicity and to fit withing our time constraints we had to
		fallback to the static UI text renderer which is overkill if used to refresh text
		every frame.
	*/
	local		time_string = "",
				update_ui = false

	// Store the knight starting position to compute score.
	local		knight_pos = ItemGetWorldPosition(knight_item).z

	/*
		Start the main loop.
		We'll stay here until time runs out or unitl the knight reaches the level end.
	*/
	while	(!knight_script.exit_reached && (time_left > 0.0))
	{
		// Apply the score bonus stored in the knight script instance.
		g_score += knight_script.score_bonus
		knight_script.score_bonus = 0

		// Prevent negative score, its too difficult to accept :p...
		if	(g_score < 0)
			g_score = 0

		// Apply the time bonus stored in the knight script instance.
		time_left += knight_script.time_bonus
		knight_script.time_bonus = 0

		// Update the score & time UI text widget.
		if	(update_ui)
			TextSetText(score_window[1], format("1UP %d", g_score.tointeger()))
		update_ui = false

		// Compute the new 'Time' string.
		local		new_time_string = format("Time %ds", time_left.tointeger())

		// If different...
		if	(time_string != new_time_string)
		{
			// ...update text.
			TextSetText(time_window[1], new_time_string)
			time_string = new_time_string
			update_ui = true
		}

		// Remove elapsed seconds from the remaining time.
		time_left -= g_dt_frame

		/*
			Compute score change by taking the difference in position
			of the player from the last frame.
		*/
		local		new_knight_pos = ItemGetWorldPosition(knight_item).z
		g_score += (new_knight_pos - knight_pos) * 50
		knight_pos = new_knight_pos

		// Throw an exception if 10 seconds elapsed and we were running the bench mode.
		if	(g_bench && time_left < 30.0)
			throw("End of benchmark.")

		// Done for this frame, suspend.
		suspend("Game")
	}

	//-------------------------------------------------------------------------------------


	//-------------------------------------------------------------------------------------
	// The end of game screen.
	//-------------------------------------------------------------------------------------

	// Switch to the finish camera.
	SwitchToCamera(g_scene, ItemCastToCamera(SceneFindItem(g_scene, "Finish Camera")))

	// Block knight controls.
	knight_script.stop_controls = true

	// If we are here because we ran out of time, display the Game Over.
	if	(time_left <= 0)
	{
		// Play a sad, sad tune.
		MixerSoundStart(EngineGetMixer(g_engine), sfx_game_over)

		// Move the message window and set it up to appear with a scale effect using command lists.
		WindowSetPosition(message_window[0], 640, 480)
		TextSetText(message_window[1], "~~Color(255, 255, 255, 255)Time Out!!!\n~~Size(48)~~Color(220, 200, 200, 255)You're done running, Knight Gyslain...")
		WindowSetCommandList(message_window[0], "toscale 0, 4, 4 + toalpha 0, 0; toalpha 0.15, 1 + toscale 0.15, 1.5, 1.5;")

		// Fade out score, time and life windows.
		WindowSetCommandList(time_window[0], "toalpha 0.1, 0;")
		WindowSetCommandList(score_window[0], "toalpha 0.1, 0;")
		WindowSetCommandList(life_icon_window, "toalpha 0.1, 0;")
	}

	// Use ACE to pause for the next 15s.
/*
	UISetCommandList(ui, "nop 15;")
	while (!UIIsCommandListDone(ui))
*/
	suspend("Game")

	// If we are here because we finished the level, transfer remaining time to score.
	if	(time_left > 0)
	{
		// As long as there is time left...
		while (time_left > 0)
		{
			// For each second removed...
			time_left -= 1
			TextSetText(time_window[1], format("Time %d", time_left.tointeger()))

			// ...grant 1000 point score bonus.
			g_score += 1000
			TextSetText(score_window[1], format("1UP %d", g_score.tointeger()))

			// Wait 250ms.
			local wait = g_clock
			while ((g_clock - wait) < 250)
				suspend("Game")
		}

		// Fade out the score, time and life windows.
		WindowSetCommandList(time_window[0], "nop 1.5; toalpha 0.25, 0;")
		WindowSetCommandList(score_window[0], "nop 1.5; toalpha 0.25, 0;")
		WindowSetCommandList(life_icon_window, "nop 1.5; toalpha 0.25, 0;")
	}

	// Set the global UI to fade out...
	UISetCommandList(ui, "nop 2.5; globalfade 1.0, 1.0;")
	while (!UIIsCommandListDone(ui))
		// ...and wait until its done.
		suspend("Game")

	// Level done, return the appropriate state code to the scene instance caller.
	return knight_script.exit_reached ? "YouWin" : "YouLoose"
}
//-----------------------------------------------------------------------------------------
