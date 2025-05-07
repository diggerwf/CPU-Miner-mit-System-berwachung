#!/bin/bash

# Pfad zum Repository (aktueller Ordner)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR" || exit

# Remote-Repository URL
REMOTE_URL="https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git"
BRANCH="main"

# Dateien
UPDATE_SCRIPT="$REPO_DIR/update.sh"
TEMP_UPDATE_SCRIPT="$REPO_DIR/update.sh.2"

# Funktion, um den aktuellen Commit-Hash zu bekommen
get_current_hash() {
    git rev-parse HEAD 2>/dev/null
}

# Funktion, um den Remote-Commit-Hash zu bekommen
get_remote_hash() {
    git ls-remote "$REMOTE_URL" "$BRANCH" | awk '{print $1}'
}

# Prüfen, ob das Repository vorhanden ist
if [ -d "$REPO_DIR/.git" ]; then
    echo "Repository gefunden. Prüfe auf Updates..."
    cd "$REPO_DIR" || exit

    # Lokale Änderungen verwerfen (Vorsicht!)
    echo "Verwerfe lokale Änderungen..."
    git reset --hard

    # Hole den neuesten Stand vom Remote
    echo "Hole neueste Änderungen vom Remote..."
    git fetch origin

    LOCAL_HASH=$(get_current_hash)
    REMOTE_HASH=$(get_remote_hash)

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "Update für update.sh erkannt."

        # Kopiere die aktuelle update.sh nach update.sh.2
        cp "$UPDATE_SCRIPT" "$TEMP_UPDATE_SCRIPT"

        # Aktualisiere update.sh durch den Pull vom Remote
        echo "Aktualisiere update.sh..."
        git pull origin "$BRANCH"

        # Stelle sicher, dass update.sh ausführbar ist
        chmod +x "$UPDATE_SCRIPT"

        # Führe die neue update.sh aus (rekursiv)
        bash "$UPDATE_SCRIPT"

        # Lösche temporäre Datei
        rm -f "$TEMP_UPDATE_SCRIPT"

        # Beende das aktuelle Skript, da die neue Version jetzt läuft
        exit 0
    else
        echo "Das Repository ist bereits aktuell."
    fi
else
    # Falls das Repository nicht existiert, klone es neu
    echo "Repository nicht gefunden. Klone es..."
    git clone "$REMOTE_URL" "$REPO_DIR"
fi

# Stelle sicher, dass update.sh immer ausführbar ist (am Ende des Skripts)
chmod +x "$UPDATE_SCRIPT"

echo "Update abgeschlossen oder kein Update erforderlich."
