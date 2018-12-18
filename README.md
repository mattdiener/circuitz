# circuitz

Circuitz is a puzzle game where the main objective is to power all of the game's sinks.

![]{./docs/gameplay_example.gif}

## Controls
This game's controls are pretty simple:
- Move your mouse to select a group of 4 tiles. Your mouse needs to be in the top-left of the group that you want to select.
- **Left Click** &mdash; rotate the group clockwise
- **Right Click** &mdash; rotate the group counter-clockwise

## Debug Mode + Other Toggles
Debug mode is essentially a level editor. Here are some things that can be done:
- **~** &mdash; enables debug mode (disables regular controls and allows single-tile highlighting)
- **F1** &mdash; shows an overlay that labels each tile with its rotation value
- **F2** &mdash; toggles level completion (stops you from accidentally completing levels)

### In debug mode:
- **w, a, s, d** &mdash; translates the highlighted tile in the appropriate direction (swaps with existing tiles)
- **r** &mdash; cycles the highlighted grid space through different backboard types
- **t** &mdash; cycles the highlighted grid space through different tile types
- **i, j** &mdash; shrinks the board vertically, horizontally respecitvely
- **k, l** &mdash; grows the board vertically, horizontally respecitvely

## Console Commands
For now, console commands can be run through the shell that you use to launch the game. The commands that currently exist are:
- **load <LEVEL_NAME>** &mdash; loads *<LEVEL_NAME>.json*
- **save <LEVEL_NAME>** &mdash; saves the level in its current state to *<LEVEL_NAME>.json*
- **save_hard <LEVEL_NAME>** &mdash; does the same as above but will overwrite an existing level if it exists *<LEVEL_NAME>.json*
