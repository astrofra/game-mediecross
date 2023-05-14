/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	Barrel
{
	player_item		=	0

	function	OnUpdate(item)
	{
		// Do nothing if the item is already awake.
		if	(!ItemIsSleeping(item))
			return

		// Compute the distance to the player on the Z axis.
		local	distance_to_player = ItemGetWorldPosition(item).z - ItemGetWorldPosition(player_item).z

		// If this distance gets below 28 meters...
		if	(distance_to_player < Mtr(28.0))
			// ...wake up physics item.
			ItemWake(item)
	}

	function	OnPhysicStep(item, step_taken)
	{
		/*
			Note: This callback is only called once the item has been woke up.
			Force a constant angular velocity, let the friction se the barrel in motion.
		*/
		ItemSetAngularVelocity(item, Vector(-8.0, 0, 0))
	}

	function	OnSetup(item)
	{
		local	scene = ItemGetScene(item)

		// Disable all rotations on the object Y axis.
		ItemPhysicSetAngularFactor(item, Vector(1.0, 0.0, 1.0))
		// Disable all motion on the object X axis.
		ItemPhysicSetLinearFactor(item, Vector(0, 1.0, 1.0))

		// Grab the knight controller.
		player_item = SceneFindItem(scene, "knight/Controller")
	}

	function	OnSetupDone(item)
	{
		/*
			Put the item to sleep in the SetupDone() callback because
			the item physic object is created during item setup.
		*/
		ItemSleep(item)
	}
}
