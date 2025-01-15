#!/usr/bin/env bash

# Set variables
# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Directory of the MHW game
MHW_DIR="$(dirname "$DIR")"
# File path to the log of changes (relative to the MHW_DIR)
# It is relative because of some weird quirks of `jq` that i'd rather not debug.
MOD_LOG_PATH="Mods/changes.json"

#Ensure that jo is installed
if ! command -v jo &> /dev/null; then
  echo "jo could not be found. Please install it."
  exit 1
fi
# Ensure that jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq could not be found. Please install it."
  exit 1
fi
# Ensure that unzip is installed
if ! command -v unzip &> /dev/null; then
  echo "unzip could not be found. Please install it."
  exit 1
fi


echo "MHW_DIR: $MHW_DIR"

# Ensure changes.json exists
if [ ! -f "$MOD_LOG_PATH" ]; then
  echo "Generating changes.json"
  echo "{}" > "$MOD_LOG_PATH"
fi

get_mod_name() {
  mod_path="$1"
  # Get the .zip file name, no directoies included
  # Handle folders with spaces
  #mod_name="$(basename "$mod_path" .zip)" 
  mod_name=$(basename "$mod_path" .zip)
  echo "$mod_name"
}
# Function to install mods
# Given a path to a zip folder to unzip in the nativePC folder
install_mods() {
  # Get the mod path
  mod_path="$1"

  # Check if the mod path exists
  if [ ! -f "$mod_path" ]; then
    echo "Mod path does not exist: $mod_path"
    return 1
  fi
  
  # Get all the files that will be unziped
  IFS=$'\n' read -r -d '' -a change_list <<< "$(unzip -Z1 "$mod_path")"
  echo "Files to be added:"
  printf '%s\n' "${change_list[@]}"

  # Warn user about mods not using the standard nativePC/ structure
  echo "WARNING: This script does not check for mods that do not use the standard nativePC/ structure."
  echo "Please ensure that these files are all under the nativePC/ folder. If not, please re-zip them manually and try again."
  echo "Stracker's loader is known to have two files outside nativePC/, this is normal."

  # Ask user for confirmation
  read -p "Do you want to continue? (y/N) " -n 1 -r
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then # if not y or Y
    echo "Exiting!"
    return 1
  fi

  # Unzip the mod into the $MHW_DIR directory
  unzip -o "$mod_path" -d "$MHW_DIR" | grep -v inflating

  # Get the mod name
  mod_name="$(get_mod_name "$mod_path")"

  # Add the changes to the log (jo is way easier than jq)
  cat "$MOD_LOG_PATH" | jo -p -f - "$mod_name=$(jo -a "${change_list[@]}")" > "$MOD_LOG_PATH"
  
  # Print the changes
  cat "$MOD_LOG_PATH" | jq

  return 0
}

# Function to remove mods
# Look up the mod's changes and undo them
remove_mods() {
  # Get the mod path
  mod_path="$1"

  # Check if the mod path exists
  if [ ! -f "$mod_path" ]; then
    echo "Mod path does not exist: $mod_path"
    return 1
  fi
  
  # Get the mod name
  mod_name="$(get_mod_name "$mod_path")"

  # Check if the mod is in the log returns true or "false"
  mod_found=$(jq 'has("'$mod_name'")' "$MOD_LOG_PATH")
  if [ "$mod_found" == "false" ]; then
    echo "Mod not found in log: $mod_name"
    return 1
  fi

  # Get the list of file changes from the log
  change_list=($(jq -r '.["'$mod_name'"][]' "$MOD_LOG_PATH"))
  echo "Files to be removed:"
  printf '%s\n' "${change_list[@]}"


  # Ask user for confirmation
  read -p "Do you want to continue? (y/n) " -n 1 -r
  echo # Move to a new line
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then # if not y or Y
    echo "Exiting!"
    return 1
  fi

  # Undo the changes in reverse order
  # Because its in reverse order, it will remove the most deeply nested files first, then check if the directory is empty and remove it
  for ((i=${#change_list[@]}-1; i>=0; i--)); do
    # Determine if the change is a directory
    if [ -d "$MHW_DIR/${change_list[$i]}" ]; then
      # If the directory is empty, remove it
      if [ -z "$(ls -A "$MHW_DIR/${change_list[$i]}")" ]; then
        rmdir "$MHW_DIR/${change_list[$i]}" && echo "Removed: $MHW_DIR/${change_list[$i]}"
      else
        # So it doesn't take out other mods with it.
        echo "Directory not empty: $MHW_DIR/${change_list[$i]}, skipping"
      fi
    else
      # Remove the file
      rm -f "$MHW_DIR/${change_list[$i]}" && echo "Removed: $MHW_DIR/${change_list[$i]}"
    fi
  done

  # Print the changes
  cat "$MOD_LOG_PATH" | jq
  
  return 0
}

# Handle initial arguments
handler() {
  # Skip this if the command is list
  if [ "$1" != "list" ]; then
    # Get the absolute path of the mod
    MOD_PATH_ABS="$(realpath "$2")"
  fi
  

  if [ "$1" == "add" ]; then
    install_mods "$MOD_PATH_ABS"
  elif [ "$1" == "remove" ]; then
    remove_mods "$MOD_PATH_ABS"
  elif [ "$1" == "list" ]; then
    cat "$MOD_LOG_PATH" | jq
  else
    echo "Invalid command: $1"
  fi
}

handler $1 $2 $3
exit
