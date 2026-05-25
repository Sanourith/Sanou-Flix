#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

ssd_dir="/media/psowl/SSD4OWL"

# Demander le nom de la série
read -p "Entrez le nom de la série (ex: Dan_Da_Dan): " series_name

if [[ -z "$series_name" ]]; then
    echo "Erreur: Le nom de la série ne peut pas être vide"
    exit 1
fi

file_to_oper="2.2_Animes/$series_name"

cd "$ssd_dir/$file_to_oper" || exit 1

# Trouver tous les dossiers (sauf "." et "more") et les trier alphabétiquement
season_dirs=($(find . -maxdepth 1 -type d ! -name "." ! -name "more" -printf "%P\n" | sort))

# Chercher les fichiers vidéo à la racine (hors dossiers)
loose_videos=($(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sort))

# S'il y a des fichiers loose ET des dossiers, créer "more"
if [[ ${#loose_videos[@]} -gt 0 ]] && [[ ${#season_dirs[@]} -gt 0 ]]; then
    echo "Fichiers vidéo trouvés hors dossiers, création du dossier 'more'..."
    mkdir -p "more"

    for video in "${loose_videos[@]}"; do
        echo "  Déplacement: $(basename "$video") -> more/"
        mv "$video" "more/"
    done

    echo ""
fi

# Si aucun dossier n'existe, créer S01 avec les fichiers de la racine
if [[ ${#season_dirs[@]} -eq 0 ]]; then
    echo "Aucun dossier de saison trouvé, création de S01..."

    # Chercher les fichiers vidéo directement dans le dossier racine
    video_files=($(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | sort))

    if [[ ${#video_files[@]} -eq 0 ]]; then
        echo "Aucun fichier vidéo trouvé"
        exit 1
    fi

    # Créer S01
    mkdir -p "S01"

    # Déplacer et renommer les fichiers
    episode_num=1
    for video in "${video_files[@]}"; do
        ext="${video##*.}"
        new_name="${series_name}_S01E$(printf '%02d' $episode_num).${ext}"
        echo "  Déplacement: $(basename "$video") -> S01/$new_name"
        mv "$video" "S01/$new_name"
        ((episode_num++))
    done

    echo "S01 créée avec ${#video_files[@]} épisode(s)"
    exit 0
fi

echo "Dossiers trouvés: ${#season_dirs[@]}"
echo "Série: $series_name"
echo ""

# Traiter chaque dossier dans l'ordre
season_num=1

for dir in "${season_dirs[@]}"; do
    old_name="$dir"
    new_season_dir="S$(printf '%02d' $season_num)"

    echo "=== Traitement de $old_name ==="

    # Vérifier si le dossier a déjà le bon nom
    need_rename=true
    if [[ "$old_name" == "$new_season_dir" ]]; then
        need_rename=false
    fi

    # Renommer les épisodes
    episode_num=1

    while IFS= read -r -d '' episode; do
        ext="${episode##*.}"
        new_episode_name="${series_name}_S$(printf '%02d' $season_num)E$(printf '%02d' $episode_num).${ext}"

        echo "  Renommage: $(basename "$episode") -> $new_episode_name"

        if $need_rename; then
            # Créer le nouveau dossier et y déplacer les fichiers
            mkdir -p "$new_season_dir"
            mv "$episode" "$new_season_dir/$new_episode_name"
        else
            # Renommer sur place
            mv "$episode" "$old_name/$new_episode_name"
        fi

        ((episode_num++))
    done < <(find "$old_name" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) -print0 | sort -z)

    # Supprimer l'ancien dossier s'il est vide et renommé
    if $need_rename && [[ -d "$old_name" ]] && [[ -z "$(ls -A "$old_name")" ]]; then
        rmdir "$old_name"
        echo "  Dossier renommé: $old_name -> $new_season_dir"
    fi

    echo ""
    ((season_num++))
done

echo "Renommage terminé!"
