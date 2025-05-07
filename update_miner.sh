#!/bin/bash

# Funktion, um Dateien/Verzeichnisse zu ignorieren
ignore_files() {
    # .gitignore erstellen oder ergänzen
    touch .gitignore

    if ! grep -qx "cpuminer-multi/" .gitignore; then
        echo "Füge 'cpuminer-multi/' zu .gitignore hinzu"
        echo "cpuminer-multi/" >> .gitignore
    fi

    if ! grep -qx "user.data" .gitignore; then
        echo "Füge 'user.data' zu .gitignore hinzu"
        echo "user.data" >> .gitignore
    fi

    # Dateien aus dem Index entfernen (falls vorhanden)
    git rm --cached -r cpuminer-multi/ 2>/dev/null || true
    git rm --cached user.data 2>/dev/null || true

    # Änderungen an .gitignore hinzufügen (ohne commit)
    git add .gitignore
}

# Funktion, um Konflikte automatisch mit 'theirs' zu lösen (ohne commit)
resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)

    for file in $CONFLICT_FILES; do
        echo "[INFO] Automatisch löse Konflikt in $file"
        git checkout --theirs -- "$file"
        git add "$file"
    done
}

main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: Dateien ignorieren..."
    ignore_files

    # Schritt 2: Lokale Änderungen stashen (falls vorhanden)
    echo "[INFO] Stashe lokale Änderungen..."
    git stash push -u -k || true

    # Schritt 3: Versuche, den Branch zu pullen und Konflikte automatisch zu lösen
    echo "[INFO] Hole neueste Änderungen vom Remote..."

    if ! git pull origin main; then
        echo "[WARN] Konflikte beim Pull erkannt. Versuche automatische Lösung..."
        resolve_conflicts

        # Erneut versuchen, den Pull abzuschließen (falls notwendig)
        git pull origin main || true
    fi

    # Schritt 4: Gestashte Änderungen wiederherstellen
    echo "[INFO] Wende gestashte Änderungen an..."
    git stash pop || true

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten
main
