#!/bin/bash

# Funktion zum automatischen Lösen von Konflikten
resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    for file in $CONFLICT_FILES; do
        if [ "$file" == "update_miner.sh" ]; then
            echo "[INFO] Konflikt in $file - behalte lokale Version..."
            git checkout --ours -- "$file"
            git add "$file"
        else
            echo "[INFO] Konflikt in $file - löse manuell."
        fi
    done
}

main() {
    # Sicherstellen, dass update_miner.sh nicht im Stash bleibt
    git stash push -u -- update_miner.sh

    # Pull durchführen (wie vorher)
    git fetch origin main

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "[INFO] Dein Branch ist aktuell."
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "[INFO] Merge wird durchgeführt..."
        git merge origin/main
    else
        echo "[WARN] Divergenz erkannt."
    fi

    # Stash wieder anwenden und Konflikte lösen
    if git stash list | grep -q 'WIP on main'; then
        git stash pop || {
            echo "[WARN] Fehler beim Anwenden des Stashes."
        }
        resolve_conflicts
    else
        echo "[INFO] Kein Stash zum Anwenden."
    fi

    echo "[SUCCESS] Update abgeschlossen."
}

main
