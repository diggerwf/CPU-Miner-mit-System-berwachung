#!/bin/bash

USER_FILE="user.git"
FILE_TO_CHECK="update_miner.sh"
BRANCH="main"

setup_git_user() {
    if [ ! -f "$USER_FILE" ]; then
        echo "[INFO] $USER_FILE nicht gefunden. Bitte gib deine Git-Benutzerdaten ein."
        read -p "Gib deine Git-E-Mail ein: " user_email
        read -p "Gib deinen Git-Namen ein: " user_name

        echo "email=$user_email" > "$USER_FILE"
        echo "name=$user_name" >> "$USER_FILE"

        git config --global user.email "$user_email"
        git config --global user.name "$user_name"

        echo "[INFO] Git-User-Daten wurden gespeichert und konfiguriert."
    else
        source "$USER_FILE"
        if [ -z "$email" ] || [ -z "$name" ]; then
            echo "[WARN] $USER_FILE ist unvollständig. Bitte lösche sie oder aktualisiere sie."
            exit 1
        fi

        git config --global user.email "$email"
        git config --global user.name "$name"
        echo "[INFO] Git-User-Daten aus $USER_FILE wurden geladen."
    fi
}

resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    if echo "$CONFLICT_FILES" | grep -q "$FILE_TO_CHECK"; then
        echo "[INFO] Konflikt in $FILE_TO_CHECK erkannt. Lösung wird angewendet..."
        git checkout --ours -- "$FILE_TO_CHECK"
        git add "$FILE_TO_CHECK"
        git commit -m "Automatisch Konflikt in $FILE_TO_CHECK gelöst"
        echo "[INFO] Konflikt in $FILE_TO_CHECK wurde automatisch gelöst und committet."
    fi
}

main() {
    echo "=== Miner Update Script ==="

    setup_git_user

    # Schritt 2: Änderungen an update_miner.sh sichern (falls vorhanden)
    if git status --porcelain | grep -q "$FILE_TO_CHECK"; then
      echo "[INFO] Sichern der Änderungen an $FILE_TO_CHECK..."
      git stash push -u -- "$FILE_TO_CHECK"
      STASHED=1
    else
      STASHED=0
    fi

    # Schritt 3: .gitignore aktualisieren (nur falls nötig, sonst auskommentieren)
    #echo "[INFO] Vorbereitung: .gitignore aktualisieren..."
    #cat <<EOL > .gitignore
#cpuminer-multi/
#user.data
#EOL
    #git add .gitignore

    # Schritt 4: Neueste Änderungen vom Remote holen (fetch + merge)
    echo "[INFO] Hole neueste Änderungen vom Remote..."
    git fetch origin $BRANCH

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then 
        echo "[INFO] Dein Branch ist aktuell."

    elif [ "$LOCAL" = "$BASE" ]; then 
        echo "[INFO] Es gibt neue Änderungen im Remote. Merge wird durchgeführt..."
        git merge origin/$BRANCH || { 
            echo "[WARN] Merge-Konflikte erkannt. Versuche automatische Lösung..."; 
            resolve_conflicts; 
        }

    else 
        echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
    fi

    # Schritt 5: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
    if [ $STASHED -eq 1 ]; then 
        echo "[INFO] Wende gestashte Änderungen an..."
        git stash pop || { 
            echo "[WARN] Fehler beim Anwenden des Stashes."; 
            resolve_conflicts;
            exit 1; 
        }

        # Konflikte in update_miner.sh automatisch lösen, falls vorhanden
        resolve_conflicts

    else 
        echo "[INFO] Kein Stash zum Anwenden."
    fi

    # Optional: Alle Änderungen zusammenfassen und finalisieren, falls noch ungestaged Änderungen bestehen:
    if ! git diff --cached --quiet; then 
        git commit -am "Automatisierte Aktualisierung inklusive Konfliktlösung"
        echo "[INFO] Änderungen committet."
    fi

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

main "$@"
