/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

Include("scripts/visual_fx.nut")

// These are the different states the character can be in.
enum	State
{
	Idle,
	Walk,
	Run,
	Jump,
	SpringJump,
	Hit
}

/*
*/
class	CharacterControl
{
//-----------------------------------------------------------------------------------------

	// SFX holder variables.
	sfx_mixer			=	0

	sfx_jump			=	0
	sfx_springboard		=	0
	sfx_barrel_hit		=	0
	sfx_pop				=	0
	sfx_food			=	0

	visual_fx			=	0

	/*
		Load all character related sounds.
		Note: Sounds are cached by the engine automatically.
	*/
	function	LoadSound()
	{
		sfx_jump		=	EngineLoadSound(g_engine, "sfx/sfx_jump_normal.ogg")
		sfx_springboard	=	EngineLoadSound(g_engine, "sfx/sfx_spring_board.ogg")
		sfx_barrel_hit	=	EngineLoadSound(g_engine, "sfx/sfx_hit_barrel.ogg")
		sfx_food		=	EngineLoadSound(g_engine, "sfx/sfx_food.ogg")
		sfx_pop			=	EngineLoadSound(g_engine, "sfx/sfx_pop.ogg")
	}

//-----------------------------------------------------------------------------------------

	current_motion		=	null
	current_source		=	null

	// Declare the available motions in the take.
	motion_bank	=
	{
		Idle		=	{	name = "Idle", take = "Take 001", start = 2.0 / 30.0, end = 94.0 / 30.0	}
		Walk		=	{	name = "Walk", take = "Take 001", start = 95.0 / 30.0, end = 111.0 / 30.0, scale = 0.5	}
		Walk_Back	=	{	name = "Walk", take = "Take 001", start = 95.0 / 30.0, end = 111.0 / 30.0, scale = -0.8	}
		Run			=	{	name = "Run", take = "Take 001", start = 95.0 / 30.0, end = 111.0 / 30.0, scale = 0.8	}
		Shoot		=	{	name = "Shoot", take = "Take 001", start = 140.0 / 30.0, end = 170.0 / 30.0, blend = Sec(0.1)	}
		Jump		=	{	name = "Jump", take = "Take 001", start = 112.0 / 30.0, end = 125.0 / 30.0, blend = Sec(0.1)	}
		// 126 - 153 Jump in place
		Hit			=	{	name = "Hit", take = "Take 001", start = 154.0 / 30.0, end = 155.0 / 30.0, blend = Sec(0.1)	}
	}

	// Set a motion.
	function	SetMotion(item, motion)
	{
		// If the motion is already applied, return immediately.
		if	(current_motion == motion)
			return
		current_motion = motion

		// Start the new animation on the correct item set (specific group or all items).
		local	source = GroupSetMotion(SceneFindGroup(scene, "Biped"), motion.take, "blend" in motion ? motion.blend : Sec(0.2))
		current_source = source

		// Set the animation source to repeat on specific timecodes.
		AnimationSourceGroupSetLoopMode(source, AnimationRepeat)
		AnimationSourceGroupSetLoop(source, motion.start, motion.end)

		// Set the animation source clock scale.
		AnimationSourceGroupSetClockScale(source, "scale" in motion ? motion.scale : 1)
	}

//-----------------------------------------------------------------------------------------

	scene				=	null

	// Setup controller.
	function	OnSetup(item)
	{
		scene = ItemGetScene(item)

		// Create the visual FX instance.
		visual_fx = VisualFX(scene)

		// Disable all physics induced rotations on this item.
		ItemPhysicSetAngularFactor(item, Vector(0, 0, 0))

		// Load sound FXs.
		sfx_mixer		=	EngineGetMixer(g_engine)
		LoadSound()

		// Switch to the idle state.
		SetMotion(item, motion_bank.Idle)
		state = State.Idle
	}

	stop_controls		=	false
	exit_reached		=	false

	time_bonus			=	0.0
	score_bonus			=	250

	// Called when the character controller enters a trigger.
	function	OnEnterTrigger(item, trigger_item)
	{
		// Get trigger name.
		local	trigger_name = ItemGetName(trigger_item)

		// Catch the end of source trigger.
		if	(trigger_name == "end_course")
			exit_reached = true

		else	if	(trigger_name == "Food Trigger")
		{
			/*
				Retrieve the trigger parent item script instance of the "Food" class and call its Eat() function.
				This function is defined in food.nut and swaps the meat mesh to the bone mesh as well
				as activating physics on the food item and applying an upward impulse to it.
			*/
			ItemGetScriptInstanceFromClass(ItemGetParent(trigger_item), "Food").Eat()

			// Launch sfx, apply time and score bonus (the bonuses are collected from this class by the level script during each updates, see 'level.nut').
			MixerSoundStart(sfx_mixer, sfx_food)
			time_bonus += 0.5
			score_bonus += 250
		}
	}

//-----------------------------------------------------------------------------------------

	function	OnGroundCollision(item)
	{
		/*
			Reaction to a ground collision depends on the current character state.
			We do not take any action except for the Jump, SpringJump and Hit states.
		*/
		switch	(state)
		{
			case	State.Jump:
			case	State.SpringJump:
			case	State.Hit:
				// If the prevent landing delay is elapsed...
				if	(prevent_landing <= 0.0)
				{
					// Switch to the idle state.
					SetMotion(item, motion_bank.Idle)
					state = State.Idle

					// Display a visual FX.
					visual_fx.ShowFX(visual_fx.GetLandFXIndex(), ItemGetWorldPosition(item))
				}
				break;
		}
	}

	invincibility_delay =	0

	function	TakeHit(item)
	{
		// React to a hit depending on the current character state.
		switch	(state)
		{
			// Do not take a hit if already taking one.
			case	State.Hit:
				break;

			// For all other states...
			default:
				// Apply a score malus.
				score_bonus -= 500

				// Set character state to Hit.
				SetMotion(item, motion_bank.Hit)
				state = State.Hit

				// Display a random hit visual FX.
				visual_fx.ShowFX(visual_fx.GetHitFXIndex(), ItemGetWorldPosition(item))

				// Apply an impulse to instantly change the item velocity and make it move up.
				ItemApplyLinearImpulse(item, Vector(0.0, 4.0, -6.0))

				/*
					Exclude for 3 seconds this item from the 'enemy' collision group.
					Doing so will prevent any collision with a barrel from happening.
				*/
				ItemSetCollisionMask(item, 5)		// Collide with all but group 2 (second bit in mask)
				invincibility_delay = Sec(3)		// Invincible for 3 seconds.

				break;
		}
	}

	function	OnCollision(item, with_item)
	{
		// Determine the type of collision happening.
		local	with_name = ItemGetName(with_item)

		// Check for a barrel collision.
		if	(with_name == "barrel")
			TakeHit(item)

		// Otherwise check for a ground collision.
		else
		{
			/*
				Many different objects are part of what we call 'ground',
				so we quickly check all of the ground parts name against our collider.
			*/
			local	ground_names = ["Ground", "ground", "Tile", "tile_slow", "slope"]

			foreach (name in ground_names)
				if	(with_name == name)
					OnGroundCollision(item)			// We have a ground collision which will be handled by a specific function.
		}
	}

//-----------------------------------------------------------------------------------------

	state				=	State.Idle

	prevent_landing		=	0.0

	function	UpdateControls(item)
	{
		// Update the invincibility delay.
		if	(invincibility_delay > 0)
		{
			// Subtract the elapsed second count since last call.
			invincibility_delay -= g_dt_frame

			// If the delay is elapsed, reenable collisions with the 'enemy' collision group.
			if	(invincibility_delay <= 0)
				ItemSetCollisionMask(item, 7)
		}

		local	device = GetKeyboardDevice();

		// React to keyboard events depending on the current character state.
		switch	(state)
		{
			// ----------------------------------------------------------------------------
			// When idle: The down, up and left keys make the character run.
			// ----------------------------------------------------------------------------

			case	State.Idle:
				if	(	DeviceIsKeyDown(device, KeyDownArrow) ||
						DeviceIsKeyDown(device, KeyUpArrow) ||
						DeviceIsKeyDown(device, KeyRightArrow)		)
				{
					// Switch to the run state.
					SetMotion(item, motion_bank.Run)
					state = State.Run
				}
				break;

			// ----------------------------------------------------------------------------
			// During a spring jump: The up and down keys strafe the character.
			// ----------------------------------------------------------------------------

			case	State.SpringJump:

				// Apply impulses to move the character along the X axis in space.
						if	(DeviceIsKeyDown(device, KeyDownArrow))
						ItemApplyLinearImpulse(item, Vector(3.0, 0, 0))
				else	if	(DeviceIsKeyDown(device, KeyUpArrow))
						ItemApplyLinearImpulse(item, Vector(-3.0, 0, 0))

				/*
					We apply an additional downward impulse to reduce the jump duration
					and effectively increase gravity.
				*/
				ItemApplyLinearImpulse(item, Vector(0, -0.4, 0))
				break;

			// ----------------------------------------------------------------------------
			// During a jump: Increase gravity by applying a downward impulse.
			// ----------------------------------------------------------------------------

			case	State.Jump:
				ItemApplyLinearImpulse(item, Vector(0, -0.4, 0))

				/*
					***NOTE THE MISSING BREAK***

					The code for the Jump state will continue executing the code for the
					Walk and Run states. This is intentional since those 3 states share all
					but one line of code.
				*/

			// ----------------------------------------------------------------------------
			// When walking or running: Up and down keys strafe the character.
			// ----------------------------------------------------------------------------

			case	State.Walk:
			case	State.Run:
			{
				local	no_key = true

				// Apply forward motion and log the key press for the idle test.
				if	(DeviceIsKeyDown(device, KeyRightArrow))
				{
					ItemApplyLinearImpulse(item, Vector(0, 0, 3.0))
					no_key = false
				}

				// Strafe the character on up and down key press.
						if	(DeviceIsKeyDown(device, KeyDownArrow))
						ItemApplyLinearImpulse(item, Vector(3.0, 0, 0))
				else	if	(DeviceIsKeyDown(device, KeyUpArrow))
						ItemApplyLinearImpulse(item, Vector(-3.0, 0, 0))

				/*
					If the player is not jumping and no key has been pressed,
					go back to the idle state.
				*/
				else	if	((state != State.Jump) && no_key)
				{
					SetMotion(item, motion_bank.Idle)
					state = State.Idle
				}
			}
			break;
		}

		/*
			In order to reduce the amount of duplicate code a second seperate switch
			is done here to handle jumping.
		*/
		switch	(state)
		{
			// ----------------------------------------------------------------------------
			// When idle, walking or running: Space makes the character jump.
			// ----------------------------------------------------------------------------

			case	State.Idle:
			case	State.Walk:
			case	State.Run:
				if	(DeviceIsKeyDown(device, KeySpace))
				{
					// Switch to the Jump state and motion.
					SetMotion(item, motion_bank.Jump)
					state = State.Jump

					// Apply an upward linear impulse to the physics item.
					ItemApplyLinearImpulse(item, Vector(0.0, 15.5, 0.0))

					// Start a sound FX and a visual FX for the jump.
					MixerSoundStart(sfx_mixer, sfx_jump)
					visual_fx.ShowFX(4, ItemGetWorldPosition(item))

					// Prevent landing for the next 0.1 seconds.
					prevent_landing = Sec(0.1)
				}
				break;

			// ----------------------------------------------------------------------------
			// When jumping or taking a hit: Elapse the prevent landing delay.
			// ----------------------------------------------------------------------------

			case	State.Jump:
			case	State.SpringJump:
			case	State.Hit:
				prevent_landing -= g_dt_frame
				break;
		}
	}

//-----------------------------------------------------------------------------------------

	function	GameplayUpdate(item)
	{
		/*
			Raytrace downward from the knight feet to detect gameplay features such as
			spring jumps or slowing tiles.
			Note: We do not explore further than 3 meters down under the character feet.
		*/
		local	_t = SceneCollisionRaytrace(scene, ItemGetWorldPosition(item) + Vector(0, 0.5, 0), Vector(0,-1,0), 7, CollisionTraceAll, Mtr(3.0))

		// If no hit, return immediately.
		if	(!_t.hit)
			return

		// Debug the hit point by drawing a 3D cross in world space.
		// RendererDrawCross(g_render, _t.p)

		// Retrieve the hit item name.
		local	hit_name = ItemGetName(_t.item)

		// React to the gameplay feature depending on the current character state.
		switch	(state)
		{
			// ----------------------------------------------------------------------------
			// When running: If we hit a slope, take a spring jump.
			//				 Slowing tiles forces the character to walk.
			// ----------------------------------------------------------------------------

			case	State.Run:
				if	(hit_name == "slope")
				{
					// Switch to the SpringJump state (play a normal jump motion).
					SetMotion(item, motion_bank.Jump)
					state = State.SpringJump

					// Apply a large upward impulse.
					ItemApplyLinearImpulse(item, Vector(0.0, 18.0, 4.0))

					// Start sound and visual FX.
					MixerSoundStart(sfx_mixer, sfx_springboard)
					visual_fx.ShowFX(4, ItemGetWorldPosition(item))

					// Prevent landing for the next 0.1 seconds.
					prevent_landing = Sec(0.1)
				}
				else	if	(hit_name == "tile_slow")
				{
					// Switch to the Walk state.
					SetMotion(item, motion_bank.Walk)
					state = State.Walk
				}
				break;

			// ----------------------------------------------------------------------------
			// When walking: If we are not on a slowing tile then switch back to the run state.
			// ----------------------------------------------------------------------------

			case	State.Walk:
				if	(hit_name != "tile_slow")
				{
					// Switch back to the Run state.
					SetMotion(item, motion_bank.Run)
					state = State.Run
				}
				break;
		}
	}

//-----------------------------------------------------------------------------------------

	function	OnPhysicStep(item, step_taken)
	{
		// If the controls are stopped...
		if	(stop_controls)
		{
			// ...and exit was reached, we simply keep on walking.
			if	(exit_reached)
			{
				// Switch to the Walk state.
				SetMotion(item, motion_bank.Walk)
				state = State.Walk

				// Apply a constant walk impulse to move the character.
				ItemApplyLinearImpulse(item, Vector(0, 0, 3.0))
			}

			// ...if the exit was not reached, simply stay idling.
			else
			{
				SetMotion(item, motion_bank.Idle)
				state = State.Idle
			}
		}

		// ... otherwise, update gameplay and react to controls.
		else
		{
			GameplayUpdate(item)
			UpdateControls(item)
		}

		/*
			On each physics step of the simulation we adjust the current character
			velocity depending on its current state.
		*/

		// Get the current linear velocity of the controller item.
		local	v = ItemGetLinearVelocity(item)

		// This is the default attenuation factor.
		v.x *= 0.75

		switch	(state)
		{
			// Idling stops the character very fast.
			case	State.Idle:		v.z *= 0.5;		break;

			// Spring jumps are unaffected and keep a constant speed.
			case	State.SpringJump:				break;

			// Jump, Walk and Run were all hand tweaked to give acceptable gameplay results.
			case	State.Jump:		v.z *= 0.715;	break;
			case	State.Walk:		v.z *= 0.575;	break;
			case	State.Run:		v.z *= 0.775;	break;
		}

		// Set back the modified linear velocity.
		ItemSetLinearVelocity(item, v)
	}

//-----------------------------------------------------------------------------------------

}
