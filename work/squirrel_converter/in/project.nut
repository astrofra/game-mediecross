/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/


g_score				<-	0		// Global score.
g_current_level		<-	0		// Current level.
g_retry_count		<-	2		// How many retries before the game is over.

/*
	Set to true to enable benchmarking.
	The game will launch directly at level 3 and throw an exception
	after 10 seconds are elapsed.
*/
g_bench				<-	false


//-----------------------------------------------------------------------------------------
class	SimpleGameProject
{
	screen_logic	=	0

	function	OnUpdate(project)
	{
		// Call the current logic instance Dispatch function.
		screen_logic.dispatch(this, project)
	}

	function	OnSetup(project)
	{
		/*
			Instantiate the default screen logic class.

			If we are benchmarking then it is the game logic class, otherwise start at
			the title screen by instantiating the title screen logic class.
		*/
		screen_logic = g_bench ? GameScreenLogic() : TitleScreenLogic()
	}
}
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
class	TitleScreenLogic
{
	dispatch			=	0
	scene				=	0

	function	Setup(game, project)
	{
		// Instantiate the title scene.
		scene = ProjectInstantiateScene(project, "scenes/title.nms")
		// Add to the project layer display stack.
		ProjectAddLayer(project, scene, 0.5)

		// Dispatch to the Update() function of this instance.
		dispatch = Update
	}

	function	Update(game, project)
	{
		local instance = ProjectSceneGetInstance(scene)

		// Query the current scene "Title" class instance for its state.
		if	(SceneGetScriptInstanceFromClass(instance, "Title").state == "startgame")
		{
			// Fade out UI.
			UISetCommandList(SceneGetUI(instance), "globalfade 0.5, 1;")

			// Set the dispatch function to the FadeOut function of this class.
			dispatch = FadeOut
		}
	}

	function	FadeOut(game, project)
	{
		// If the UI global fade is done.
		if	(UIIsCommandListDone(SceneGetUI(ProjectSceneGetInstance(scene))))
		{
			// Unload the title scene.
			ProjectUnloadScene(project, scene)

			// Instantiate the game logic class as the current screen logic instance.
			game.screen_logic = GameScreenLogic()
		}
	}

	constructor()
	{
		/*
			Dispatch to the Setup function.

			This can be seen as a pointer to function, calling dispatch() after this
			assignation will be strictly equivalent as calling Setup directly.
		*/
		dispatch = Setup
	}
}
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
class	GameScreenLogic
{
	dispatch			=	0
	scene				=	0

	function	Setup(game, project)
	{
		// Instantiate the current game level.
		scene = ProjectInstantiateScene(project, "scenes/level_" + g_current_level + ".nms")
		// Add to the project layer display stack.
		ProjectAddLayer(project, scene, 0.5)

		// Dispatch to the Update() function of this instance.
		dispatch = Update
	}

	function	Update(game, project)
	{
		local instance = ProjectSceneGetInstance(scene)

		// Query the current scene "SceneLevel" class instance for its state.
		local	game_state = SceneGetScriptInstanceFromClass(instance, "SceneLevel").state

		// If the scene state requires a game over...
		if	(game_state == "YouLoose")
		{
			// ...unload the current level scene.
			ProjectUnloadScene(project, scene)

			// If we have no more retries left...
			if	(g_retry_count <= 0)
				// ...go back to the title screen logic.
				game.screen_logic = TitleScreenLogic()

			else
			{
				// Remove a retry.
				g_retry_count--
				// Reload the same level.
				dispatch = Setup
			}
		}
		// If it requires ending the level...
		else	if	(game_state == "YouWin")
		{
			// ...unload the current level scene.
			ProjectUnloadScene(project, scene)

			// Increase the current level counter.
			g_current_level++;

			// If we are done with all the levels.
			if	(g_current_level == 7)
					// Instantiates the end screen logic class, congratulations!
					game.screen_logic = EndScreenLogic()
			else
					// Dispatch back to the Setup function to load the next level.
					dispatch = Setup
		}
	}

	constructor()
	{
		// Reset score and the current level.
		g_score = 0
		g_current_level = g_bench ? 2 : 0
		g_retry_count = 2

		// Dispatch to the Setup function.
		dispatch = Setup
	}
}
//-----------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
class	EndScreenLogic
{
	dispatch			=	0
	scene				=	0

	function	Setup(game, project)
	{
		// Instantiate the end scene.
		scene = ProjectInstantiateScene(project, "scenes/end_screen.nms")
		// Add to the project layer display stack.
		ProjectAddLayer(project, scene, 0.5)

		// Dispatch to the Update() function of this instance.
		dispatch = Update
	}

	function	Update(game, project)
	{
		local instance = ProjectSceneGetInstance(scene)

		// Query the current scene "EndScreen" class instance for its state and if it's done...
		if	(SceneGetScriptInstanceFromClass(instance, "EndScreen").is_done)
		{
			// ...unload the end scene.
			ProjectUnloadScene(project, scene)
			// Instantiates the title screen logic class.
			game.screen_logic = TitleScreenLogic()
		}
	}

	constructor()
	{
		// Dispatch to the Setup function.
		dispatch = Setup
	}
}
//-----------------------------------------------------------------------------------------
