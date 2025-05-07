#!/bin/bash

# Funktion, um Dateien/Verzeichnisse zu ignorieren
ignore_files() {
    # .gitignore erstellen oder ergänzen
    touch .gitignore

    # Sicherstellen, dass 'cpuminer-multi/' ignoriert wird
    if ! grep -qx "cpuminer-multi/" .gitignore; then
        echo "Füge 'cpuminer-multi/' zu .gitignore hinzu"
        echo "cpuminer-multi/" >> .gitignore
    fi

    # Sicherstellen, dass 'user.data' ignoriert wird
    if ! grep -qx "user.data" .gitignore; then
        echo "Füge 'user.data' zu .gitignore hinzu"
        echo "user.data" >> .gitignore
    fi

    # Sicherstellen, dass 'update_miner.sh' ignoriert wird
    if ! grep -qx "update_miner.sh" .gitignore; then
        echo "Füge 'update_miner.sh' zu .gitignore hinzu"
        echo "update_miner.sh" >> .gitignore
    fi

    # Dateien aus dem Index entfernen (falls vorhanden)
    git rm --cached -r cpuminer-multi/ 2>/dev/null || true
    git rm --cached user.data 2>/dev/null || true

    # Entferne update_miner.sh aus dem Cache, falls vorhanden
    git rm --cached update_miner.sh 2>/dev/null || true

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

    # Schritt 0: Stelle sicher, dass update_miner.sh nicht im Index ist,
    # damit es keine Konflikte beim Mergen gibt.
    git rm --cached update_miner.sh 2>/dev/null || true

    # Schritt 1: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: Dateien ignorieren..."
    ignore_files

    # Schritt 2: Lokale Änderungen stashen (falls vorhanden)
    echo "[INFO] Stashe lokale Änderungen..."
    git stash push -u -k || true

    # Schritt 3: Nur neueste Änderungen vom Remote holen (fetch)
    echo "[INFO] Hole neueste Änderungen vom Remote..."
    git fetch origin main

    # Prüfen, ob der lokale Branch hinter dem Remote ist
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
   BASE=$(git merge-base @ @{u})

   if [ "$LOCAL" = "$REMOTE" ]; then
       echo "[INFO] Dein Branch ist aktuell. Keine Updates notwendig."
   elif [ "$LOCAL" = "$BASE" ]; then
       echo "[INFO] Es gibt neue Änderungen im Remote. Du kannst jetzt 'git merge' oder 'git rebase' durchführen."
       # Optional: Automatisches Mergen hier aktivieren:
       # git merge origin/main
   else
       echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
   fi

   # Schritt 4: Gestashte Änderungen wiederherstellen
   echo "[INFO] Wende gestashte Änderungen an..."
   git stash pop || true

   echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten
main
