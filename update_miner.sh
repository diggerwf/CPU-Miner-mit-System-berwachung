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

main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Sicherstellen, dass update_miner.sh nicht im Stash bleibt
    echo "[INFO] Sichern der Änderungen an update_miner.sh..."
    git stash push -u -- update_miner.sh

    # Schritt 2: Dateien ignorieren und in Git eintragen
    echo "[INFO] Vorbereitung: Dateien ignorieren..."
    ignore_files

    # Schritt 3: Neueste Änderungen vom Remote holen (fetch + merge)
    echo "[INFO] Hole neueste Änderungen vom Remote..."

    git fetch origin main

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
   BASE=$(git merge-base @ @{u})

   if [ "$LOCAL" = "$REMOTE" ]; then
       echo "[INFO] Dein Branch ist aktuell. Keine Updates notwendig."
   elif [ "$LOCAL" = "$BASE" ]; then
       echo "[INFO] Es gibt neue Änderungen im Remote. Merge wird durchgeführt..."
       git merge origin/main
   else
       echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
   fi

   # Schritt 4: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
   echo "[INFO] Wende gestashte Änderungen an..."

   if git stash list | grep -q 'WIP on main'; then
       git stash pop || {
           echo "[WARN] Konflikte beim Anwenden des Stashes. Löse sie manuell."
           exit 1
       }
   else
       echo "[INFO] Kein Stash zum Anwenden."
   fi

   echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten
main
