#!/bin/bash

set -e

ssd_path="/media/${USER}/SSD4OWL"

films_path="$ssd_path/1_Films"
anime_path="$ssd_path/2.2_Animes"
series_path="$ssd_path/2_Series"

declare -a list_films=()
declare -a list_animes=()
declare -a list_series=()

nb_films=0

# --- FILMS ---
for file in "$films_path"/*; do
  [[ -d "$file" ]] && continue

  file_name=$(basename "$file")
  file_extension="${file_name##*.}"    # extract only extension .xxx
  file_basename="${file_name%.*}"      # extract all name without extension

  list_films+=$file_name
  ((nb_films++))

  # TODO inject csv for all
  # OR
  # TODO etl part for database_name
  # TODO database injection part
done

