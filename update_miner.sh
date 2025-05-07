#!/bin/bash

# Variablen
USER_FILE="user.git"
FILE_TO_CHECK="update_miner.sh"
BRANCH="main"

# Funktion: Git-User-Daten laden oder setzen
setup_git_user() {
    if [ ! -f "$USER_FILE" ]; then
        echo "[INFO] $USER_FILE nicht gefunden. Bitte gib deine Git-Benutzerdaten ein."
        read -p "Gib deine Git-E-Mail ein: " user_email
        read -p "Gib deinen Git-Namen ein: " user_name
        echo "email=$user_email" > "$USER_FILE"
        echo "name=$user_name" >> "$USER_FILE"
        git config --global user.email "$user_email"
        git config --global user.name "$user_name"
        echo "[INFO] Git-User-Daten wurden gespeichert und konfiguriert."
    else
        source "$USER_FILE"
        if [ -z "$email" ] || [ -z "$name" ]; then
            echo "[WARN] $USER_FILE ist unvollständig. Bitte lösche sie oder aktualisiere sie."
            exit 1
        fi
        git config --global user.email "$email"
        git config --global user.name "$name"
        echo "[INFO] Git-User-Daten aus $USER_FILE wurden geladen."
    fi
}

# Funktion: Konflikte automatisch lösen (inkl. Löschkonflikte)
resolve_conflicts() {
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    if echo "$CONFLICT_FILES" | grep -q "$FILE_TO_CHECK"; then
        echo "[INFO] Konflikt in $FILE_TO_CHECK erkannt. Lösung wird mit --theirs oder Löschung angewendet..."

        # Prüfen, ob die Datei im Index vorhanden ist (nicht gelöscht)
        if git ls-files --error-unmatch "$FILE_TO_CHECK" > /dev/null 2>&1; then
            # Datei existiert noch -> löse mit --theirs
            git checkout --theirs -- "$FILE_TO_CHECK"
            git add "$FILE_TO_CHECK"
            git commit -m "Automatisch Konflikt in $FILE_TO_CHECK gelöst mit --theirs"
        else
            # Datei wurde gelöscht -> lösche sie auch lokal
            git rm "$FILE_TO_CHECK"
            git commit -m "Datei $FILE_TO_CHECK aufgrund des Remote-Löschens entfernt"
        fi

        # Miner neu starten nach Konfliktlösung
        ./start_miner.sh -u
    fi
}

# Hauptfunktion
main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Git-User-Daten setzen/laden
    setup_git_user

    # Schritt 2: Änderungen an update_miner.sh sichern (falls vorhanden)
    if git status --porcelain | grep -q "^ M\?$FILE_TO_CHECK"; then
      echo "[INFO] Sichern der Änderungen an $FILE_TO_CHECK..."
      git stash push -u -- "$FILE_TO_CHECK"
      STASHED=1
    else
      STASHED=0
    fi

    # Schritt 3: Neueste Änderungen vom Remote holen (fetch + merge)
    echo "[INFO] Hole neueste Änderungen vom Remote..."
    git fetch origin $BRANCH

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then 
        echo "[INFO] Dein Branch ist aktuell."

    elif [ "$LOCAL" = "$BASE" ]; then 
        echo "[INFO] Es gibt neue Änderungen im Remote. Merge wird durchgeführt..."
        if ! git merge origin/$BRANCH; then 
            echo "[WARN] Merge-Konflikte erkannt. Versuche automatische Lösung..."
            resolve_conflicts
            # Nach Konfliktlösung erneut versuchen zu mergen:
            git merge origin/$BRANCH || { 
                echo "[ERROR] Merge konnte nicht abgeschlossen werden."; 
                exit 1; 
            }
        fi

    else 
        echo "[WARN] Dein Branch ist ahead oder diverged. Bitte prüfe den Status."
    fi

    # Schritt 4: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
    if [ $STASHED -eq 1 ]; then
      echo "[INFO] Wende gestashte Änderungen an..."
      if ! git stash pop; then
          echo "[WARN] Fehler beim Anwenden des Stashes. Versuche automatische Konfliktlösung..."
          resolve_conflicts
          # Erneut versuchen, Stash anzuwenden:
          git stash pop || { 
              echo "[ERROR] Fehler beim Anwenden des Stashes nach Konfliktlösung."; 
              exit 1; 
          }
      fi

      # Falls noch Konflikte bestehen, nochmal prüfen und lösen:
      resolve_conflicts

    else
      echo "[INFO] Kein Stash zum Anwenden."
    fi

    # Schritt 5: Alle Änderungen zusammenfassen und finalisieren, falls noch ungestaged Änderungen bestehen:
    if ! git diff --cached --quiet; then
      git commit -am "Automatisierte Aktualisierung inklusive Konfliktlösung"
      echo "[INFO] Änderungen committet."
    fi

    # Miner neu starten am Ende des Updates (falls gewünscht)
    ./start_miner.sh -u

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten
main "$@"
