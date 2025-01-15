# Simple Bash Script for Monster Hunter World Mod Management for Linux Gamers
## Legal
I am not responsible if your use of this script results in any negative consequences. Please look through the script before running.
## Why?
I'm too lazy to figure out how to get the popular `.exe` Mod Manager to work on Linux

## Dependencies
The script will tell you if you are missing dependencies, but:
- jq
- jo
- unzip
## Installation
1. Enter the Monster Hunter World game folder, typically `/home/USERNAME/.steam/steam/steamapps/common/Monster Hunter World`
2. `$``git clone https://github.com/trm109/linux-mhw-mod-manager Mods`
    - **Important!** Make sure you clone it as `Mods`. Weird stuff will happen otherwise.
3. Download your mods into a subdirectory of `Mods`. For example, `./Mods/Core/strackers-loader.zip`
    - **Important!** Please use kebab-case/dash-case for the zip file names (NO SPACES). Weird stuff will happen otherwise. 
## Usage
From the MHW directory, `$``./Mods/manager.sh add ./Mods/Core/strackers-loader.zip`
- Deleting Mods: `$``./Mods/manager.sh remove ./Mods/Core/strackers-loader.zip`
- List Mods: `$``./Mods/manager.sh list`
    - Functionally equivalent to `$``cat ./Mods/changes.json | jq`
