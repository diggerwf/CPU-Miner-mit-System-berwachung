#!/bin/bash

# Funktion zum automatischen Lösen von Konflikten
resolve_conflicts() {
    # Prüfen, ob Konflikte bestehen
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

    # Schritt 1: Änderungen an update_miner.sh sichern (falls vorhanden)
    git stash push -u -- update_miner.sh

    # Schritt 2: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: .gitignore aktualisieren..."
    cat <<EOL > .gitignore
cpuminer-multi/
user.data
update_miner.sh
EOL
    git add .gitignore

    # Schritt 3: Neueste Änderungen vom Remote holen (fetch + merge)
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
        # Optional: Weitere Maßnahmen bei Divergenz.
    fi

    # Schritt 4: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
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

    # Optional: Alle Änderungen zusammenfassen und finalisieren
    # Falls noch ungestaged Änderungen bestehen:
    if ! git diff --cached --quiet; then
        git commit -am "Automatisierte Aktualisierung inklusive Konfliktlösung"
        echo "[INFO] Änderungen committet."
    fi

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten
main
