#!/bin/bash

# Selbst die Ausführungsrechte setzen
chmod +x "$0"

REPO_DIR="$HOME/CPU-Miner-mit-System-berwachung"
BRANCH="main"

cd "$REPO_DIR" || { echo "Verzeichnis nicht gefunden"; exit 1; }

# Prüfen auf unmerged Konflikte
if git ls-files -u | grep -q .; then
    echo "Es gibt Merge-Konflikte. Bitte diese manuell lösen."
    exit 1
fi

# Prüfen, ob Änderungen oder untracked Files vorhanden sind
if ! git diff-index --quiet HEAD -- || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Änderungen oder untracked Files erkannt."
    if [ -f "update_miner.sh" ]; then
        echo "Entferne spezifische untracked Datei: update_miner.sh"
        rm -f "update_miner.sh"
    fi
fi

# Stashen bei lokalen Änderungen
if ! git diff-index --quiet HEAD --; then
    echo "Änderungen erkannt. Stashe sie temporär..."
    git stash save "Automatisches Stash vor Update"
    STASHED=true
fi

# Fetch und Merge
git fetch origin

# Überprüfen, ob der lokale Branch hinter dem Remote ist
LOCAL=$(git rev-parse "$BRANCH")
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "Repository ist bereits auf dem neuesten Stand."
else
    # Prüfen auf Konflikte vor dem Pullen
    if git ls-files -u | grep -q .; then
        echo "Merge-Konflikte erkannt. Bitte diese manuell lösen."
        exit 1
    fi

    echo "Neue Version verfügbar! Aktualisiere..."
    git pull origin "$BRANCH"
fi

# Änderungen wiederherstellen
if [ "$STASHED" = true ]; then
    echo "Stash wiederherstellen..."
    git stash pop
fi

# Nach Update: Berechtigungen für start_miner.sh setzen (falls vorhanden)
if [ -f "./start_miner.sh" ]; then
    chmod +x ./start_miner.sh
    echo "Ausführungsrechte für start_miner.sh gesetzt."
fi

echo "Update abgeschlossen."
