#!/bin/bash

USER_FILE="user.git"

# Funktion zum Einrichten der Git-User-Daten
setup_git_user() {
    if [ ! -f "$USER_FILE" ]; then
        echo "[INFO] user.git Datei nicht gefunden. Bitte gib deine Git-Benutzerdaten ein."
        read -p "Gib deine Git-E-Mail ein: " user_email
        read -p "Gib deinen Git-Namen ein: " user_name

        # Speichern in der Datei
        echo "email=$user_email" > "$USER_FILE"
        echo "name=$user_name" >> "$USER_FILE"

        # Konfiguration setzen
        git config --global user.email "$user_email"
        git config --global user.name "$user_name"

        echo "[INFO] Git-User-Daten wurden gespeichert und konfiguriert."
    else
        # Daten aus der Datei lesen
        source "$USER_FILE"
        if [ -z "$email" ] || [ -z "$name" ]; then
            echo "[WARN] $USER_FILE ist unvollständig. Bitte lösche sie oder aktualisiere sie."
            exit 1
        fi

        # Konfiguration setzen
        git config --global user.email "$email"
        git config --global user.name "$name"
        echo "[INFO] Git-User-Daten aus $USER_FILE wurden geladen."
    fi
}

# Funktion zum automatischen Lösen von Konflikten in update_miner.sh
resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    if echo "$CONFLICT_FILES" | grep -q 'update_miner.sh'; then
        echo "[INFO] Konflikt in update_miner.sh erkannt. Lösung wird angewendet..."
        git checkout --ours -- update_miner.sh
        git add update_miner.sh
        git commit -m "Automatisch Konflikt in update_miner.sh gelöst"
        echo "[INFO] Konflikt in update_miner.sh wurde automatisch gelöst und committet."
    fi
}

main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Git-Benutzerdaten konfigurieren/laden
    setup_git_user

    # Schritt 2: Änderungen an update_miner.sh sichern (falls vorhanden)
    git stash push -u -- update_miner.sh

    # Schritt 3: .gitignore aktualisieren und hinzufügen
    echo "[INFO] Vorbereitung: .gitignore aktualisieren..."
    cat <<EOL > .gitignore
cpuminer-multi/
user.data
update_miner.sh
EOL
    git add .gitignore

    # Schritt 4: Neueste Änderungen vom Remote holen (fetch + merge)
    echo "[INFO] Hole neueste Änderungen vom Remote..."

    git fetch origin main

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "[INFO] Dein Branch ist aktuell."
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "[INFO] Es gibt neue Änderungen im Remote. Merge wird durchgeführt..."
        git merge origin/main || {
            echo "[WARN] Merge-Konflikte erkannt. Versuche automatische Lösung..."
            resolve_conflicts
        }
    else
        echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
    fi

    # Schritt 5: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
    if git stash list | grep -q 'WIP on main'; then
        echo "[INFO] Wende gestashte Änderungen an..."
        git stash pop || {
            echo "[WARN] Fehler beim Anwenden des Stashes."
            exit 1
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

# Skript starten
main
