# Undertale Battle Demo
This repository contains the abandoned WIP code for a SNES port of the Undertale battle system. This project originally started on 30 August 2020 before being modified to specifically be a Ganon fight in the same style for the A Link to the Past 2020 Fall Festive Randomizer. This code is being released for others to study and mock as an example of a homebrew Super Nintendo game built from scratch.

This source code can be assembled as-is into a working ROM with the included `build.bat` file. The program [asar v1.71+](https://github.com/RPGHacker/asar/releases/latest) is required to build this software. A pre-built version of the presented source code can be found on [this repository's releases page](https://github.com/spannerisms/UndertaleBattleDemo/releases/latest).

# Copyright Implications
All material—code, data, graphics—was built from naught, as such, I am the sole copyright holder of 99% of the material contained within this software. 1% (the Ganon sprite) is the intellectual property of artist FishWaffle64. While this program's debut was in a hack of a commercially licensed game, it made no use of that software's functions (in fact, it disabled them to full hijack the game). With no commercially licensed material from other sources being present, this source code and the resulting software are thus allowed to be distributed freely without legal repercussions.

The use of the character Ganon and the art/play style of Undertale is to be considered parody. You have to admit this is kind of funny.

# Notes on Code
* Certain parts of the code are written robustly, allowing up to 3 enemies per combat situation. Other parts are hardcoded or otherwise restricted to expect a single enemy: Ganon.
* The 60hz NMI vector is not utilized in this ROM as it was simpler to handle the vertical blanking period manually, rather than rerouting the vanilla software's interrupt routines. As a standalone ROM, it makes more sense to use the built-in NMI. As a hijack, it was less complex to do so manually.
* The included program `singlesheet.jar` can be used to create new 2bpp or 4bpp graphics for this ROM. New graphics should follow the templates of the included `.png` files, where the top half of the image contains the 2kb graphics data visually and the bottom half contains palette data used to interpret the graphics data.