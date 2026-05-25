#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

##### CHANGE DIRECTORY FOR SERIES' ONE IF NEEDED (eg "2.3_Series")
ssd_dir="/media/psowl/SSD4OWL/2.2_Animes"

# ASK DIR NAME
read -p "Enter the name of the directory you'll rename (eg: Dan_Da_Dan): " series_name

if [[ -z "$series_name" ]]; then
    echo "Error: cannot be empty"
    exit 1
fi

cd "$ssd_dir/$series_name" || exit 1

mapfile -t season_dirs < <(find . -maxdepth 1 -type d ! -name "." ! -name "more" -printf "%P\n" | sort)
mapfile -t loose_videos < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sort)

# echo "${season_dirs[@]}"
# echo "${loose_videos[@]}"


###
# IF THERE IS SEASONS DIR BUT LOOSES EPISODES
# >> MODE EPISODES TO 'more' DIRECTORY
###
if [[ ${#loose_videos[@]} -gt 0 ]] && [[ ${#season_dirs[@]} -gt 0 ]]; then
  echo "Video found without dir, creating 'more' content..."
  mkdir -p "Additional_content"

  for video in "${loose_videos[@]}"; do
    echo "  >>> Moving: $(basename "$video") -> more/"
    mv "$video" "Additional_content/"
  done

  echo ""
fi


############      PART 1 - IF NO DIRECTORIES
# IF THERE IS NO SEASON DIR
# >> MODE EVERY FILES INTO S01 DIR
###
if [[ ${#season_dirs[@]} -eq 0 ]]; then
  echo "No season_dir found, creating S01..."

  mapfile -t video_files < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sort)

  if [[ ${#video_files} -eq 0 ]]; then
    echo "No video file found"
    exit 1
  fi

  mkdir -p "TO_BE_MODIFIED"

  episode_num=1
  for video in "${video_files[@]}"; do
    # ext="${video##*.}"
    # new_name="${series_name}_S01E$(printf '%02d' $episode_num).${ext}"
    # echo "  Moving $(basename "$video") >> S01/$new_name"
    mv "$video" "S01/$video"
  done

  echo "TO_BE_MODIFIED directory into $series_name saga"
  exit 0
fi

############      PART 2 - IF SEASON DIRECTORIES DETECTED


## Demon_Slayer
