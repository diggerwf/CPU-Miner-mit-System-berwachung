#!/bin/bash

# Überprüfen, ob der Parameter -u übergeben wurde
if [ "$1" == "-u" ]; then
    ./update_miner.sh
    exit 0
fi

# Funktion zum Abfragen der Wallet- und Pool-Adresse
frage_daten() {
    echo "Bitte Wallet-Adresse eingeben:"
    read -r WALLET_ADDRESS
    echo "Bitte Pool-URL eingeben (z.B. stratum+tcp://public-pool.io:21496):"
    read -r POOL_URL
    # Speichern der Daten in der Datei
    echo "WALLET_ADDRESS=\"$WALLET_ADDRESS\"" > "$DATA_FILE"
    echo "POOL_URL=\"$POOL_URL\"" >> "$DATA_FILE"
}

# Variablen
SESSION_NAME="btc-miner"
MINER_VERZEICHN="$HOME/CPU-Miner-mit-System-berwachung/cpuminer-multi"
DATA_FILE="user.data"

# Parameterverarbeitung (bestehender Code)
if [[ "$1" == "-w" ]]; then
    echo "Lösche gespeicherte Daten..."
    rm -f "$DATA_FILE"
    echo "Daten gelöscht. Das Skript wird beendet."
    exit 0
elif [[ "$1" == "-i" ]]; then
    if [ -f "$DATA_FILE" ]; then
        source "$DATA_FILE"
        echo "Geladene Daten:"
        echo "Wallet: $WALLET_ADDRESS"
        echo "Pool: $POOL_URL"
    else
        frage_daten
        source "$DATA_FILE"
    fi
elif [[ "$1" == "-wi" ]]; then
    echo "Lösche gespeicherte Daten..."
    rm -f "$DATA_FILE"
    frage_daten
    source "$DATA_FILE"
fi

# Falls keine Daten vorhanden, abfragen
if [ ! -f "$DATA_FILE" ]; then
    frage_daten
else
    source "$DATA_FILE"
fi

# Überprüfen, ob das Verzeichnis existiert
if [ ! -d "$MINER_VERZEICHN" ]; then
    echo "Fehler: Das Verzeichnis '$MINER_VERZEICHN' existiert nicht."
    exit 1
fi

# Überprüfen, ob die Screen-Session bereits läuft
if screen -list | grep -q "$SESSION_NAME"; then
    echo "Die Screen-Session '$SESSION_NAME' läuft bereits."
else
    echo "Starte den Miner in einer neuen Screen-Session..."
    # In das Verzeichnis wechseln und Miner starten in einer Screen-Session
    cd "$MINER_VERZEICHN" && \
        screen -dmS "$SESSION_NAME" ./cpuminer -a sha256d -o "$POOL_URL" -u "$WALLET_ADDRESS" -p x

    if [ $? -eq 0 ]; then
        echo "Miner wurde erfolgreich gestartet."
    else
        echo "Fehler beim Starten des Miners."
        exit 1
    fi
fi
