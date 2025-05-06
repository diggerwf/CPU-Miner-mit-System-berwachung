#!/bin/bash

# Funktion zum Abfragen der Wallet und Pool Adresse
frage_daten() {
    echo "Bitte Wallet-Adresse eingeben:"
    read -r WALLET_ADDRESS
    echo "Bitte Pool-URL eingeben (z.B. stratum+tcp://public-pool.io:21496):"
    read -r POOL_URL

    # Speichern der Daten in der Datei
    echo "WALLET_ADDRESS=\"$WALLET_ADDRESS\"" > "$DATA_FILE"
    echo "POOL_URL=\"$POOL_URL\"" >> "$DATA_FILE"
}

# Name der Screen-Session
SESSION_NAME="btc-miner"

# Pfad zum Miner-Verzeichnis
MINER_VERZEICHN="$HOME/cpuminer-multi"

# Datei für gespeicherte Daten
DATA_FILE="user.data"

# Parameterverarbeitung
if [[ "$1" == "-w" ]]; then
    echo "Lösche gespeicherte Daten..."
    rm -f "$DATA_FILE"
    echo "Daten gelöscht. Das Skript wird beendet."
    exit 0
elif [[ "$1" == "-i" ]]; then
    # Aktionen für -i (z.B. Daten abfragen)
    if [ -f "$DATA_FILE" ]; then
        source "$DATA_FILE"
    else
        frage_daten
    fi
elif [[ "$1" == "-wi" ]]; then
    # Für -wi: Daten löschen und dann abfragen
    echo "Lösche gespeicherte Daten..."
    rm -f "$DATA_FILE"
    frage_daten
fi

# Falls keine Aktion bei -i oder -wi ausgeführt wurde, prüfe auf vorhandene Daten oder frage nach
if [ ! -f "$DATA_FILE" ]; then
    frage_daten
else
    source "$DATA_FILE"
fi

# Miner-Befehl mit Variablen
MINER_BEFELH="./cpuminer -a sha256d -o \"$POOL_URL\" -u \"$WALLET_ADDRESS\" -p x"

# Überprüfen, ob die Screen-Session bereits läuft
if screen -list | grep -q "$SESSION_NAME"; then
    echo "Die Screen-Session '$SESSION_NAME' läuft bereits."
else
    echo "Starte den Miner in einer neuen Screen-Session..."
    cd "$MINER_VERZEICHN" && \
    screen -dmS "$SESSION_NAME" bash -c "cd \"$MINER_VERZEICHN\" && $MINER_BEFELH"
    echo "Miner wurde gestartet."
fi