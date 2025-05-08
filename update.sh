#!/bin/bash

# ==========================
# Konfiguration
# ==========================
REPO_URL="https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git"
BRANCH="main"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

UPDATE_SCRIPT="$REPO_DIR/update.sh"
TEMP_UPDATE_SCRIPT="$REPO_DIR/update.sh.2"

# Liste der Dateien/Ordner, die beim Update NICHT geändert werden sollen
IGNORE_LIST=("cpuminer-multi/" "user.data")

# ==========================
# Funktionen
# ==========================

get_current_hash() {
    git rev-parse HEAD 2>/dev/null
}

get_remote_hash() {
    git ls-remote "$REPO_URL" "$BRANCH" | awk '{print $1}'
}

# ==========================
# Hauptlogik
# ==========================

cd "$REPO_DIR" || { echo "Verzeichnis nicht gefunden"; exit 1; }

# Schritt 1: Ignorierte Dateien/Ordner auf 'assume unchanged' setzen
echo "Setze ignorierte Dateien/Ordner auf 'assume unchanged'..."
for item in "${IGNORE_LIST[@]}"; do
    if [ -e "$item" ]; then
        git update-index --assume-unchanged "$item"
        echo "Markiert: $item"
    fi
done

# Schritt 2: Repository aktualisieren oder klonen
if [ -d "$REPO_DIR/.git" ]; then
    echo "Repository gefunden. Prüfe auf Updates..."
    git fetch origin

    LOCAL_HASH=$(get_current_hash)
    REMOTE_HASH=$(get_remote_hash)

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "Neues Update erkannt. Aktualisiere..."

        # Backup des eigenen update.sh vor dem Pull (optional)
        cp "$UPDATE_SCRIPT" "$TEMP_UPDATE_SCRIPT"

        # Pull die neuesten Änderungen vom Remote-Branch
        git pull origin "$BRANCH"

        # Script erneut ausführbar machen
        chmod +x "$UPDATE_SCRIPT"

        # Selbstaufruf nach Update (falls gewünscht)
        bash "$UPDATE_SCRIPT"

        # Schritt 3: Ignorierte Dateien wieder freigeben
        echo "Freigeben der ignorierten Dateien/Ordner..."
        for item in "${IGNORE_LIST[@]}"; do
            if [ -e "$item" ]; then
                git update-index --no-assume-unchanged "$item"
                echo "Freigegeben: $item"
            fi
        done

        # Temporäre Backup-Datei entfernen
        rm -f "$TEMP_UPDATE_SCRIPT"

        exit 0
    else
        echo "Das Repository ist bereits aktuell."
    fi
else
    echo "Repository nicht gefunden. Klone es..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Script immer ausführbar machen (falls noch nicht)
chmod +x "$UPDATE_SCRIPT"

echo "Update abgeschlossen oder kein Update erforderlich."
