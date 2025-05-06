#!/bin/bash

# Pfad zum lokalen Repository
REPO_DIR="$HOME/CPU-Miner-mit-System-berwachung"

# Branch, den du verwendest (z.B. main)
BRANCH="main"

# Prüfen, ob das Verzeichnis existiert
if [ ! -d "$REPO_DIR" ]; then
    echo "Repository nicht gefunden. Klone es jetzt..."
    git clone https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git "$REPO_DIR"
else
    echo "Repository gefunden. Überprüfe auf Updates..."
    cd "$REPO_DIR"

    # Fetch die neuesten Änderungen vom Remote
    git fetch origin

    # Hole die Commit-IDs
    LOCAL=$(git rev-parse "$BRANCH")
    REMOTE=$(git rev-parse "origin/$BRANCH")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "Das Repository ist bereits auf dem neuesten Stand. Kein Update notwendig."
    else
        echo "Neue Version verfügbar! Aktualisiere..."
        git pull origin "$BRANCH"
        # Optional: Miner neu starten oder andere Aktionen ausführen
        # z.B. systemctl restart miner.service
        echo "Update abgeschlossen."
    fi
fi
