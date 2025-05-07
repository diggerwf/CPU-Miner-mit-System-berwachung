#!/bin/bash

set -e  # Bei Fehler sofort beenden
set -u  # Unbekannte Variablen als Fehler behandeln
set -o pipefail  # Fehler in Pipelines erkennen
set -x  # Ausführliche Debug-Ausgaben aktivieren

# Variablen
USER_FILE="user.git"
FILE_TO_CHECK="update_miner.sh"
BRANCH="main"

# Funktion: Git-User-Daten laden oder setzen
setup_git_user() {
    if [ ! -f "$USER_FILE" ]; then
        echo "[DEBUG] $USER_FILE nicht gefunden. Bitte gib deine Git-Benutzerdaten ein."
        read -p "Gib deine Git-E-Mail ein: " user_email
        read -p "Gib deinen Git-Namen ein: " user_name
        echo "email=$user_email" > "$USER_FILE"
        echo "name=$user_name" >> "$USER_FILE"
        git config --global user.email "$user_email" || { echo "[ERROR] Git config konnte nicht gesetzt werden."; exit 1; }
        git config --global user.name "$user_name" || { echo "[ERROR] Git config konnte nicht gesetzt werden."; exit 1; }
        echo "[DEBUG] Git-User-Daten wurden gespeichert und konfiguriert."
    else
        source "$USER_FILE"
        if [ -z "$email" ] || [ -z "$name" ]; then
            echo "[ERROR] $USER_FILE ist unvollständig. Bitte lösche sie oder aktualisiere sie."
            exit 1
        fi
        git config --global user.email "$email" || { echo "[ERROR] Git config konnte nicht gesetzt werden."; exit 1; }
        git config --global user.name "$name" || { echo "[ERROR] Git config konnte nicht gesetzt werden."; exit 1; }
        echo "[DEBUG] Git-User-Daten aus $USER_FILE wurden geladen."
    fi
}

# Funktion: Konflikte automatisch lösen (inkl. Löschkonflikte)
resolve_conflicts() {
    local CONFLICT_FILES
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    if echo "$CONFLICT_FILES" | grep -q "$FILE_TO_CHECK"; then
        echo "[DEBUG] Konflikt in $FILE_TO_CHECK erkannt. Lösung wird angewendet..."

        # Prüfen, ob die Datei im Index vorhanden ist (nicht gelöscht)
        if git ls-files --error-unmatch "$FILE_TO_CHECK" > /dev/null 2>&1; then
            # Datei existiert noch -> löse mit --theirs
            echo "[DEBUG] Datei existiert noch, löse mit --theirs..."
            git checkout --theirs -- "$FILE_TO_CHECK" || { echo "[ERROR] Konfliktlösung mit --theirs fehlgeschlagen."; exit 1; }
            git add "$FILE_TO_CHECK" || { echo "[ERROR] Hinzufügen der gelösten Datei fehlgeschlagen."; exit 1; }
            git commit -m "Automatisch Konflikt in $FILE_TO_CHECK gelöst mit --theirs" || { echo "[ERROR] Commit nach Konfliktlösung fehlgeschlagen."; exit 1; }
        else
            # Datei wurde gelöscht -> lösche sie auch lokal
            echo "[DEBUG] Datei wurde gelöscht, entferne sie..."
            git rm "$FILE_TO_CHECK" || { echo "[ERROR] Entfernen der gelöschten Datei fehlgeschlagen."; exit 1; }
            git commit -m "Datei $FILE_TO_CHECK aufgrund des Remote-Löschens entfernt" || { echo "[ERROR] Commit nach Löschen fehlgeschlagen."; exit 1; }
        fi

        # Miner neu starten nach Konfliktlösung
        ./start_miner.sh -u || { echo "[ERROR] start_miner.sh konnte nicht ausgeführt werden."; exit 1; }
    fi
}

# Hauptfunktion
main() {
    echo "=== Miner Update Script ==="

    # Schritt 1: Git-User-Daten setzen/laden
    setup_git_user

    # Schritt 2: Änderungen an update_miner.sh sichern (falls vorhanden)
    if git status --porcelain | grep -q "^ M\?$FILE_TO_CHECK"; then
      echo "[DEBUG] Sichern der Änderungen an $FILE_TO_CHECK..."
      git stash push -u -- "$FILE_TO_CHECK" || { echo "[ERROR] Stash konnte nicht erstellt werden."; exit 1; }
      STASHED=1
    else
      STASHED=0
    fi

    # Schritt 3: Neueste Änderungen vom Remote holen (fetch + merge) mit Debug-Ausgaben und Fehlerüberprüfung
    echo "[DEBUG] Hole neueste Änderungen vom Remote..."
    git fetch origin || { echo "[ERROR] Fetch vom Remote fehlgeschlagen."; exit 1; }

    echo "[DEBUG] Merge branch..."
    if ! git merge origin/$BRANCH; then 
        echo "[WARN] Merge-Konflikte erkannt. Versuche automatische Lösung..."
        resolve_conflicts

        # Nach Konfliktlösung erneut versuchen zu mergen:
        if ! git merge origin/$BRANCH; then 
            echo "[ERROR] Merge konnte nach Konfliktlösung nicht abgeschlossen werden."
            exit 1
        fi
    fi

    # Schritt 4: Gestashte Änderungen wiederherstellen (inklusive update_miner.sh)
    if [ $STASHED -eq 1 ]; then
      echo "[DEBUG] Wende gestashte Änderungen an..."
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
      echo "[DEBUG] Kein Stash zum Anwenden."
    fi

	# Schritt 5: Alle Änderungen zusammenfassen und finalisieren, falls noch ungestaged Änderungen bestehen:
	if ! git diff --cached --quiet; then
		git commit -am "Automatisierte Aktualisierung inklusive Konfliktlösung" || { echo "[ERROR] Commit fehlgeschlagen"; exit 1; }
		echo "[DEBUG] Änderungen committet."
	fi

    # Miner neu starten am Ende des Updates (falls gewünscht)
    ./start_miner.sh -u || {echo "[ERROR] start_miner.sh konnte nicht ausgeführt werden."; exit 1;}

    echo "[SUCCESS] Miner wurde erfolgreich aktualisiert."
}

# Skript starten mit Fehlerbehandlung für unerwartete Probleme:
main "$@"
