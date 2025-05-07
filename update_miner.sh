#!/bin/bash

# Pfad zum lokalen Repository
REPO_DIR="$HOME/CPU-Miner-mit-System-berwachung"
BRANCH="main"

if [ ! -d "$REPO_DIR" ]; then
    echo "Repository nicht gefunden. Klone es jetzt..."
    git clone https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git "$REPO_DIR"
else
    echo "Repository gefunden. Überprüfe auf Updates..."
    cd "$REPO_DIR" || { echo "Konnte Verzeichnis nicht wechseln"; exit 1; }

    # Prüfen, ob Änderungen vorhanden sind
    if ! git diff-index --quiet HEAD --; then
        echo "Änderungen erkannt. Stashe sie temporär..."
        git stash save "Automatisches Stash vor Update"
        STASHED=true
    fi

    # Fetch die neuesten Änderungen vom Remote
    git fetch origin

    # Vergleiche lokale und remote Commit-IDs
    LOCAL=$(git rev-parse "$BRANCH")
    REMOTE=$(git rev-parse "origin/$BRANCH")

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "Das Repository ist bereits auf dem neuesten Stand. Kein Update notwendig."
    else
        echo "Neue Version verfügbar! Aktualisiere..."
        git pull origin "$BRANCH"
        # Hier kannst du z.B. den Miner neu starten
        # systemctl restart miner.service
        echo "Update abgeschlossen."
    fi

    # Wenn Änderungen gestasht wurden, wiederherstellen
    if [ "$STASHED" = true ]; then
        echo "Stash wiederherstellen..."
        git stash pop
    fi
fi
