#!/bin/bash

main() {
    echo "=== Miner Update Script ==="

    # Schritt 0: Sicherstellen, dass update_miner.sh nicht im Index ist
    git rm --cached update_miner.sh 2>/dev/null || true

    # Schritt 1: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: Dateien ignorieren..."
    ignore_files

    # Schritt 2: Lokale Änderungen stashen (falls vorhanden)
    echo "[INFO] Stashe lokale Änderungen..."
    git stash push -u -k || true

    # Schritt 3: Nur neueste Änderungen vom Remote holen (fetch)
    echo "[INFO] Hole neueste Änderungen vom Remote..."
    git fetch origin main

    # Prüfen, ob der lokale Branch hinter dem Remote ist
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "[INFO] Dein Branch ist aktuell. Keine Updates notwendig."
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "[INFO] Es gibt neue Änderungen im Remote. Mergen..."
        git merge origin/main
        if [ $? -ne 0 ]; then
            echo "[ERROR] Merge fehlgeschlagen! Konflikte beheben."
            exit 1
        fi
        echo "[SUCCESS] Update erfolgreich gemerged."
    else
        echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
    fi

    # Schritt 4: Gestashte Änderungen wiederherstellen
    echo "[INFO] Wende gestashte Änderungen an..."
    git stash pop || true

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Funktion zum Ignorieren der Dateien (wie vorher)
ignore_files() {
   # ... (wie oben)
}

# Skript starten
main
