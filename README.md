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

To auto-target type `/cb t`. If you are targeting from a 'friendly' or 'neutral' faction it will target the nearest 'hostile' combatant. If you are targeting from a 'hostile' combatant it will target the nearest 'friendly' combatant. Entering `/cb t` again will target the next nearest combatant, eventually cycling back to the nearest.

To override the target faction you can type `/cb t {faction}`. You can specify faction as `f` or `friend` for friendly, `h`, `hostile` or `foe` for hostile, or `n or `neutral` for neutral.

To target multiple combatants, add a count to the command. For example, if you wanted to cast Bless on three of your friends you could use `/cb t f 3`.

To clear your targets use `/cb c`.

Known Bugs
----------
- Players who control more than one character can only use ChatBat with the first one. Need to have it support multiple PCs.

Roadmap
-------
- More than just targeting! It will eventually include attack and damage rolls.
- The ability to reset the combat tracker after an encounter
- Use of language strings to support internationalization
