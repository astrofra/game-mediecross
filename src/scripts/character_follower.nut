/*
	Mediecross TIGS AGBIC Compo

	A game by François Gutherz, Emmanuel Julien and Ryan Hagen
	Made using GameStart (http://www.gamestart3d.com)
*/

class	PlayerFollower
{
	player_item		=	0
	follower_pos	=	0

	function	OnSetup(item)
	{
		local	scene = ItemGetScene(item)

		// Grab the character controller item.
		player_item = SceneFindItem(scene, "knight/Controller")

		// Store our initial position.
		follower_pos = ItemGetWorldPosition(item)
	}

	function	OnUpdate(item)
	{
		// Grab current player item position.
		local	player_pos = ItemGetWorldPosition(player_item)

		// Compute the new follower Z position to match the player Z position.
		follower_pos.z = Lerp(0.25, follower_pos.z, player_pos.z)

		// Apply back to this item.
		ItemSetPosition(item, follower_pos) 
	}
}
