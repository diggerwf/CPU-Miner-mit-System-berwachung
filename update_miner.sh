#!/bin/bash

# Pfad zur Datei mit den Git-Benutzerdaten
USER_FILE="user.git"

# Überprüfen, ob die Datei existiert
if [ ! -f "$USER_FILE" ]; then
  echo "Fehler: Die Datei '$USER_FILE' wurde nicht gefunden!"
  exit 1
fi

# Daten aus der Datei lesen
EMAIL=$(grep "^email=" "$USER_FILE" | cut -d'=' -f2-)
NAME=$(grep "^name=" "$USER_FILE" | cut -d'=' -f2-)

# Überprüfen, ob die Daten erfolgreich gelesen wurden
if [ -z "$EMAIL" ]; then
  echo "Fehler: Keine gültige E-Mail in '$USER_FILE' gefunden."
  exit 1
fi

if [ -z "$NAME" ]; then
  echo "Fehler: Kein gültiger Name in '$USER_FILE' gefunden."
  exit 1
fi

# Git-Konfiguration setzen (globale Konfiguration)
git config --global user.email "$EMAIL"
git config --global user.name "$NAME"

echo "Git-Benutzerdaten wurden erfolgreich aktualisiert:"
echo "Name : $NAME"
echo "Email: $EMAIL"
