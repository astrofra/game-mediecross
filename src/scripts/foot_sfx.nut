/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/


// Lock a channel globally for the foot SFX.
g_foot_sfx_channel	<-	MixerChannelLock(g_mixer)


class	FootSFX
{
	controller			=	0

	sfx_foot_step		=	0
	foot_is_up			=	true

	function	OnUpdate(item)
	{
		// Grab this foot item position.
		local	pos = ItemGetWorldPosition(item)

		// If foot is down, watch for when it is going to go up.
		if	(!foot_is_up)
		{
			if	(pos.y > 0.15)
				// Got above the 15cm threshold, foot is now up.
				foot_is_up = true
		}

		// If foot is up, watch for when it is going to come down.
		else
		{
			if	(pos.y < 0.15)
			{
				// Got below the 15cm threshold, foot is down.
				foot_is_up = false

				// If the controller speed is above 1cm/s then play a sound.
				if	(ItemGetLinearVelocity(controller).Len() > 0.01)
					MakeFootStepSound()
			}
		}
	}

	function	MakeFootStepSound()
	{
		// Compute volume from the controller speed.
		local	controller_speed = ItemGetLinearVelocity(controller).Len()
		local	volume = 0.15 * RangeAdjustClamped(controller_speed, 0.0, 5.0, 0.125, 0.5)

		// Start a random sample and adjust the engine selected channel volume.
		MixerChannelStart(g_mixer, g_foot_sfx_channel, sfx_foot_step[Irand(0, 3)])
		MixerChannelSetGain(g_mixer, g_foot_sfx_channel, volume)
	}	 

	function	OnSetup(item)
	{
		// Load all sound FX.
		sfx_foot_step	=	[]
		for	(local i = 0; i < 3; i++)
			sfx_foot_step.append(EngineLoadSound(g_engine, "sfx/sfx_clang_" + i.tostring() + ".ogg"))

		/*
			Grab controller to modulate SFX volume by the controller speed.
			Note: We first grab controller, and if we fail we try the 'Knight/Controller'
				  to be able to use that class both in the Knight scene template and ingame.
		*/
		controller = SceneFindItem(ItemGetScene(item), "Controller")
		if	(!ObjectIsValid(controller))
			controller = SceneFindItem(ItemGetScene(item), "Knight/Controller")
	}
}
