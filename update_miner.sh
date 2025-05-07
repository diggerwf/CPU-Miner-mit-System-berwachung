#!/bin/bash

# Funktion, um bestimmte Dateien/Verzeichnisse zu ignorieren
ignore_files() {
    # Prüfen, ob die Einträge bereits in .gitignore sind; wenn nicht, hinzufügen
    if ! grep -qx "cpuminer-multi/" .gitignore; then
        echo "Füge 'cpuminer-multi/' zu .gitignore hinzu"
        echo "cpuminer-multi/" >> .gitignore
    fi

    if ! grep -qx "user.data" .gitignore; then
        echo "Füge 'user.data' zu .gitignore hinzu"
        echo "user.data" >> .gitignore
    fi

    # Entferne die Dateien/verzeichnisse aus dem Git-Index, falls sie bereits verfolgt werden
    git rm --cached -r cpuminer-multi/ 2>/dev/null || true
    git rm --cached user.data 2>/dev/null || true

    # Füge die Änderungen an .gitignore hinzu und committe sie (optional)
    git add .gitignore
    git commit -m "Füge cpuminer-multi/ und user.data zu .gitignore hinzu" || true
}

# Beispiel für das Update-Skript

echo "Starte Miner-Update..."

# Schritt 1: Ignoriere bestimmte Dateien/Verzeichnisse
echo "Vorbereitung: Dateien ignorieren..."
ignore_files

# Schritt 2: Repository auf den neuesten Stand bringen
echo "Hole neueste Änderungen vom Remote..."
git fetch origin

# Schritt 3: Änderungen im lokalen Branch stashen (falls notwendig)
echo "Stashe lokale Änderungen..."
git stash push -u -k

# Schritt 4: Aktualisiere den Branch auf den neuesten Stand
echo "Aktualisiere Branch..."
git pull origin main

# Schritt 5: Stash wiederherstellen (falls vorher Änderungen gestasht wurden)
echo "Wende gestashte Änderungen an..."
git stash pop || true

# Optional: Hier kannst du dein Miner-Update oder andere Befehle hinzufügen
# z.B. Neustart des Miners, Kompilieren etc.
echo "Miner-Update abgeschlossen."

# Ende des Scripts
