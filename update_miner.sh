#!/bin/bash

# Funktion, um bestimmte Dateien/Verzeichnisse zu ignorieren
ignore_files() {
    touch .gitignore

    if ! grep -qx "cpuminer-multi/" .gitignore; then
        echo "Füge 'cpuminer-multi/' zu .gitignore hinzu"
        echo "cpuminer-multi/" >> .gitignore
    fi

    if ! grep -qx "user.data" .gitignore; then
        echo "Füge 'user.data' zu .gitignore hinzu"
        echo "user.data" >> .gitignore
    fi

    git rm --cached -r cpuminer-multi/ 2>/dev/null || true
    git rm --cached user.data 2>/dev/null || true

    git add .gitignore
    git commit -m "Füge cpuminer-multi/ und user.data zu .gitignore hinzu" || true
}

# Funktion, um Konflikte automatisch zu lösen (ohne Commit)
resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)

    for file in $CONFLICT_FILES; do
        echo "[INFO] Automatisch löse Konflikt in $file"
        # Überschreibe mit der Version vom Remote (Theirs)
        git checkout --theirs -- "$file"
        git add "$file"
    done
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

    # Schritt 3: Versuche, den Branch zu pullen und Konflikte automatisch zu lösen
    echo "[INFO] Hole neueste Änderungen vom Remote..."

    if ! git pull origin main; then
        echo "[WARN] Konflikte beim Pull erkannt. Versuche automatische Lösung..."
        resolve_conflicts

        # Nach der Lösung erneut versuchen, den Pull abzuschließen (falls notwendig)
        git pull origin main || true
    fi

    # Schritt 4: Stash wiederherstellen (falls vorher Änderungen gestasht wurden)
    echo "[INFO] Wende gestashte Änderungen an..."
    git stash pop || true

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Script starten
main
