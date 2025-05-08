#!/bin/bash

# ==========================
# Konfiguration
# ==========================
# Repository-URL und Branch
REPO_URL="https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git"
BRANCH="main"

# Pfad zum aktuellen Verzeichnis (wo das Skript liegt)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Name des Skripts (damit es sich selbst aktualisieren kann)
UPDATE_SCRIPT="$REPO_DIR/update.sh"
TEMP_UPDATE_SCRIPT="$REPO_DIR/update.sh.2"

# Liste der Dateien/Ordner, die beim Update ignoriert werden sollen
IGNORE_LIST=("config.ini" "local_data/" "meine_konfig/")

# ==========================
# Funktionen
# ==========================

# Funktion: Hash des aktuellen Repos holen
get_current_hash() {
    git rev-parse HEAD 2>/dev/null
}

# Funktion: Hash des Remote-Repos holen
get_remote_hash() {
    git ls-remote "$REPO_URL" "$BRANCH" | awk '{print $1}'
}

# ==========================
# Hauptlogik
# ==========================

cd "$REPO_DIR" || { echo "Verzeichnis nicht gefunden"; exit 1; }

# Schritt 1: Sicherung der ignorierten Dateien/Ordner vor dem Update
echo "Sicherung der ignorierten Dateien/Ordner..."
for item in "${IGNORE_LIST[@]}"; do
    if [ -e "$item" ]; then
        cp -r "$item" "$item".backup
        echo "Gesichert: $item"
    fi
done

# Schritt 2: Repository aktualisieren oder klonen
if [ -d "$REPO_DIR/.git" ]; then
    echo "Repository gefunden. Prüfe auf Updates..."
    # Hard Reset, um lokale Änderungen zu verwerfen
    git reset --hard

    # Fetch vom Remote-Repository
    git fetch origin

    LOCAL_HASH=$(get_current_hash)
    REMOTE_HASH=$(get_remote_hash)

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        echo "Neues Update erkannt. Aktualisiere..."
        # Backup des eigenen update.sh vor dem Pullen
        cp "$UPDATE_SCRIPT" "$TEMP_UPDATE_SCRIPT"

        # Pull die neuesten Änderungen vom Remote-Branch
        git pull origin "$BRANCH"

        # Stelle sicher, dass das Script weiterhin ausführbar ist
        chmod +x "$UPDATE_SCRIPT"

        # Führe das aktualisierte Script erneut aus (Self-Update)
        bash "$UPDATE_SCRIPT"

        # Nach dem Update: Wiederherstellen der ignorierten Dateien/Ordner
        echo "Wiederherstellen der ignorierten Dateien/Ordner..."
        for item in "${IGNORE_LIST[@]}"; do
            if [ -e "$item".backup ]; then
                rm -rf "$item"
                mv "$item".backup "$item"
                echo "Wiederhergestellt: $item"
            fi
        done

        # Entferne temporäre Backup-Datei des Scripts
        rm -f "$TEMP_UPDATE_SCRIPT"

        exit 0
    else
        echo "Das Repository ist bereits aktuell."
    fi
else
    echo "Repository nicht gefunden. Klone es..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# Schritt 3: Sicherstellen, dass das Script immer ausführbar ist
chmod +x "$UPDATE_SCRIPT"

echo "Update abgeschlossen oder kein Update erforderlich."
