#!/bin/bash

# Funktion, um bestimmte Dateien/Verzeichnisse zu ignorieren
ignore_files() {
    # Sicherstellen, dass .gitignore existiert
    touch .gitignore

    # Hinzufügen von cpuminer-multi/ zu .gitignore, falls noch nicht vorhanden
    if ! grep -qx "cpuminer-multi/" .gitignore; then
        echo "Füge 'cpuminer-multi/' zu .gitignore hinzu"
        echo "cpuminer-multi/" >> .gitignore
    fi

    # Hinzufügen von user.data zu .gitignore, falls noch nicht vorhanden
    if ! grep -qx "user.data" .gitignore; then
        echo "Füge 'user.data' zu .gitignore hinzu"
        echo "user.data" >> .gitignore
    fi

    # Entfernen der Dateien/verzeichnisse aus dem Git-Cache, falls sie verfolgt werden
    git rm --cached -r cpuminer-multi/ 2>/dev/null || true
    git rm --cached user.data 2>/dev/null || true

    # Änderungen an .gitignore committen (optional)
    git add .gitignore
    git commit -m "Füge cpuminer-multi/ und user.data zu .gitignore hinzu" || true
}

# Hauptfunktion für das Update-Skript
main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: Dateien ignorieren..."
    ignore_files

    # Schritt 2: Lokale Änderungen stashen (falls vorhanden)
    echo "[INFO] Stashe lokale Änderungen..."
    git stash push -u -k

    # Schritt 3: Aktuellen Branch auf den neuesten Stand bringen
    echo "[INFO] Hole neueste Änderungen vom Remote..."
    git pull origin main

    # Schritt 4: Stash wiederherstellen (falls vorher Änderungen gestasht wurden)
    echo "[INFO] Wende gestashte Änderungen an..."
    git stash pop || true

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Script starten
main
