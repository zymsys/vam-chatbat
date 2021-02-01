ChatBat (Chat comBat Extension) for Fantasy Grounds
===================================================

_This is version 0.1 and is probably buggy, and absolutely incomplete. More to come!_

This is an extension for the Fantasy Grounds virtual tabletop. It allows users to take combat actions from the chat window. Chat commands can be tragged to the toolbar and executed quickly with function keys.

It is built for CoreRPG so it should work with any ruleset.

Installation
------------
For generic extension installation instructions, see
[the support wiki](https://www.fantasygrounds.com/wiki/index.php/Data_Files_Overview#Extensions).

Copy the vam-chatbat.ext file into your extensions folder. Alternatively, if installing from git you can clone the repository into the extensions folder.

To activate the extension, select 'Vam's ChatBat - Chat comBat' from the extensions list.

How to use it
-------------
From the chat window, type `/cb` (or `/chatbat`) to get quick help.

If you are the GM, ChatBat will work with the combatant who's turn it is. If you are a player, ChatBat will work with your PC(s) only.

###Targeting
To auto-target type `/cb t`. If you are targeting from a 'friendly' or 'neutral' faction it will target the nearest 'hostile' combatant. If you are targeting from a 'hostile' combatant it will target the nearest 'friendly' combatant. Entering `/cb t` again will target the next nearest combatant, eventually cycling back to the nearest.

To override the target faction you can type `/cb t {faction}`. You can specify faction as `f` or `friend` for friendly, `h`, `hostile` or `foe` for hostile, or `n or `neutral` for neutral.

To target multiple combatants, add a count to the command. For example, if you wanted to cast Bless on three of your friends you could use `/cb t f 3`. If you are targeting enemies then you can leave out the faction and just give a count, such as `/cb t 3`.

To clear your targets use `/cb c`.

Targets can be memorized and restored. Use `/cb m` to memorize the current list of targets, and then `/cb r` to restore those targets. This is useful if you want to list more than one ChatBat command on the same line as explained below under **Command Stacking**.

###Actions
To get a list of available actions, type `/cb a`. You can then select an action with `/cb a #` where # is the number of the action. You can also give the name with `/cb a {name}` to avoid hotkeys changing when the actions on your character sheet change.

**Tip:** If you assign `/cb a` to Alt-0, and then the numbers `/cb a 1` to `/cb a 9` to Alt-1 to Alt-9 then you can very quickly see a list and select an action.

To roll damage after using ChatBat to roll an attack, use `/cb d`. Note that this only works for attacks invoked through ChatBat actions.

###Command Stacking
You can stack commands by separating them with a comma. For example, to attack the nearest enemy with a dagger and then return targeting back to how it was when you started, you could use `/cb m,t,a Dagger (M),r`. What I'd really like to offer is including the damage command in there too, but I have some work to do before that works. I need to make damage conditional on a successful attack, and I need to make stacked commands wait for dice rolls.

Known Bugs
----------
- Players who control more than one character can only use ChatBat with the first one. Need to have it support multiple PCs.
- If there are no candidate targets on the map the combatant will target themselves.

Roadmap
-------
- Support for more action types such as effects
- The ability to reset the combat tracker after an encounter
- Use of language strings to support internationalization
