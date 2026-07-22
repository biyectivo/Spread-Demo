
# Spread Demo Project

This is a demo project for [**Spread**](https://github.com/biyectivo/Spread), my Gamemaker library that lets you keep, read and live-reload game data from an XLSX workbook while developing, and use automatically-generated JSON files when in a build, seamlessly.

The assets used are from [skyel13 on itch.io](https://skyel13.itch.io/simple-tower-defense).

## Requirements

You need Gamemaker LTS 2024+ for **Windows**.

## Setting up

1. Clone the repository or download as ZIP and extract.
2. Download [this spreadsheet](https://biyectivo.com/Spread/Spread%20Demo%20Game%20Data.xlsx), which contains the game data, and place it in `C:\Users\<your username>\AppData\Local\Spread_Demo` (create the `Spread_Demo` folder, since it probably won't exist).
3. Open the Gamemaker project and the Excel spreadsheet
4. Run the game.
 
## The project
 
This is a Bloons-like tower defense stub game that uses **Spread** to read the game data from the aforementioned spreadsheet. In particular, it reads tables about:

* Enemies
* Towers
* Projectiles
* Waves

The majority of the relevant code is in the `Create` event of the `Game` object controller.

## The spreadsheet

The spreadsheet is intended to look similar to what a game designer spreadsheet would look like: different tables in different sheets or places in the document, colors/fonts, cell comments, shapes, scenarios (for example cell Q3 of the `towers` sheet, which has a dropdown that changes the projectile damage levels depending on different scenarios) etc.

## How to test Spread in Development mode

Make sure you are in Development mode (open `__Spread__Config__` and make sure the `SPREAD_DEV_MODE` macro variable is set to `true`); then open the spreadsheet with Excel or similar and run the Gamemaker project.

You can try modifying the Excel, saving it and then running the game again; or you can also try hot-reloading the values from the spreadsheet. This has already been setup in the `Step` event of the `Game` object controller:

* **E** reloads enemy data from the previously defined table
* **T** reloads tower data from the previously defined table
* **P** reloads projectile data from the previously defined table
* **W** reloads wave data from the previously defined table

**Hover** over enemies or placed towers to see their name; **hold SHIFT** while doing so to see all their **stats**.
You can **pause/unpause the game with ESC**.

Note that not all game mechanics are actually implemented.

## How to test Spread in Production mode

After running in Development mode, try changing to Production mode (and/or create a build), deleting/moving the XLSX sheet and copying the JSON directory to your `datafiles` folder. Then, run in the target platform you like - no need to modify/rewrite/delete anything from your code!