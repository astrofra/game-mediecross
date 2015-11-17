/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	Title
{
	ui			=	0
	state		=	"running"

	function	OnUpdate(scene)
	{
		// When space key is pressed...
		if	(DeviceIsKeyDown(GetKeyboardDevice(), KeySpace))
		{
			// Stop all mixer channels.
			MixerChannelStop(g_mixer, 0)
			MixerChannelSetLoopMode(g_mixer, 0, LoopNone)

			// And let the project script know that we're done executing.
			state = "startgame"
		}
	}

	function	CreateLabel(ui, name, x, y, size = 70, w = 300, h = 64)
	{
		// Create UI window.
		local	window = UIAddWindow(ui, -1, x, y, w, h)
		UIRenderSetup(ui, g_factory)

		// Center window pivot.
		WindowSetPivot(window, w / 2, h / 2)

		// Create UI text widget and set as window base widget.
		local	widget = UIAddStaticTextWidget(ui, -1, name, "garamond")
		WindowSetBaseWidget(window, widget)

		// Set text attributes.
		TextSetSize(widget, size)
		TextSetColor(widget, 0, 0, 0, 255)
		TextSetAlignment(widget, TextAlignCenter)

		// Return window.
		return window
	}

	function	OnSetup(scene)
	{
		// Load UI fonts.
		local		ui = SceneGetUI(scene)
		UILoadFont("ui/garamond.ttf")
		UILoadFont("ui/brokenscript.ttf")

		// Create press start and information labels.
		local		space_window = CreateLabel(ui, "Press Space", 640, 750, 80, 400, 80)
		WindowSetCommandList(space_window, "loop; toalpha 0.25, 1; nop 0.5; toalpha 0.25, 0; next;")

		CreateLabel(ui, "MedieCross 2010, made for TigSource.com.\nCode : Emmanuel Julien - Art : Francois Gutherz\nAnimation : Ryan Hagen - Engine : GameStart3D.com", 640, 880, 24, 900, 96)

		// Play intro music.
		MixerChannelStart(g_mixer, 0, EngineLoadSound(g_engine, "sfx/sfx_cellos_loop.ogg"))
		MixerChannelSetLoopMode(g_mixer, 0, LoopRepeat)
	}
}
