# Overview
PROJECT HUNTER is a first-person, melee combat, arena battle / platformer. Players will navigate through platforming puzzles, arena battles, and boss fights in this game.

# Inspiration & feel of the game
PROJECT HUNTER is inspired by indie games in the "boomer shooter" genre such as ULTRAKILL, DOOM (2016), DOOM ETERNAL, Boomerang X, and platformer elements games such as Neon White, Mirror's Edge, Titanfall 2, Ghostrunner.

The initial inspiration for the game came from playing Ghostrunners, and wanting more from the melee combat presented in the game. Then playing ULTRAKILL gave more inspirations on what gameplay style I wanted to emulate. The game is intended to give the players feeling like an unstoppable canonball bouncing around the arena, taking out everything in their path.

# Core gameplay loop
## Player abilities
Players are equipped with multitude of abilities and weapons. These will be given to the players bit by bit across the levels to help players get used to them.
### General overview
The core focus of the game is the interplay between mobility and combat. Many abilities will be usable for both cases. Game will feature verticality, platforming, and fast-paced combat with dodging projectiles and enemies themselves.

### Mobility
Players will be equipped with multiple mobility options.
- Basic mobility:
  - Double jump
  - High amount of control on the air.
  - High speed movement on-ground.
  - Wall-climb (Genji from Overwatch) & mantling
  - Wallrunning (Titanfall & Ghostrunner)
  - Wall jump
  - Slide which preserves player's momentum and adds speed.
  - Slam, pressing crouch in the air will have the player slam the ground, damaging and/or stunning and/or throwing enemies in the air. 
- Abilities:
  - "Bash" : directional dash that pushes the player on the horizontal axes. Follows the direction of movement input. If player colliders with an enemy, the player will stun the enemy (possibly weaken too). Can use multiple times before needing to wait for cooldown.
  - "Slash" : directional dash that follows the direction player is looking at. Has longer range than Bash. Damages enemies on the path. If enemies are killed through this ability, its cooldown is refreshed. Has higher cooldown than Bash.
  - Grappling hook: Players will be pulled towards a valid grapple target. If the enemy pulled are low-mass enemy, they are pulled towards the player instead. This will give players some float time in the air.
    - Potential to add a function so holding the grapple button will let the players swing, and tapping pulls them towards the target. Subject to change depending on the difficulty of implementation and balance of the game.

### Combat
Player will be equipped with combat tools. Players will be equipped with one or two weapons and can mix and match whichever weapons they want. Players will be able to press a hotkey and a hand button to assign said weapon to the respective hand.
- Generic sword: Close range, the benchmark weapon for all enemies. Most enemies will die in 1 hit from this weapon. Can parry projectiles and attacks with this weapon. 
- Chainsword: Similar to Blades of Chaos from God of War series. Short dagger attached to chains. Longer range from the sword, slower attack speed. same damage. 
  - May link grappling hook mechanics to the weapon. Playtest required.
- Two handed weapon: A hammer or a greatsword. BFG-like weapon that deals massive damage (AoE or otherwise) and goes on a cooldown after use. The weapon will continue cooling down when not in use.

![image](./References/Boomerang%20X.jpg)



## Level design overview
Players will be put into two general types of rooms, Arenas and Corridors. Arenas have focus on clearing out the enemies inside the Arena. 

