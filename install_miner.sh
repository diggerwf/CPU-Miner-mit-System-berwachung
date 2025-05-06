#!/bin/bash

# Skript als root oder mit sudo ausführen!

echo "System-Update und Upgrade..."
sudo apt update && sudo apt full-upgrade -y

echo "Nicht mehr benötigte Pakete entfernen..."
sudo apt autoremove -y

echo "Benötigte Pakete installieren..."
sudo apt install git automake autoconf libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev zlib1g-dev screen build-essential mosquitto-clients -y

echo "Klonen des Miners-Repositories..."
git clone https://github.com/tpruvot/cpuminer-multi
cd cpuminer-multi

echo "Autogen-Skript ausführen..."
sudo ./autogen.sh

echo "Konfigurieren..."
sudo ./configure

echo "Bauen..."
sudo ./build.sh

echo "Netdata installieren (ohne Wartezeit)..."
bash <(curl -SsL https://my-netdata.io/kickstart.sh) --dont-wait

cd ..

# Stelle sicher, dass start_miner.sh ausführbar ist
echo "Stelle sicher, dass start_miner.sh ausführbar ist..."
chmod +x start_miner.sh

# Miner in einer Screen-Session starten
echo "Miner wird jetzt in der Screen-Session 'btc-miner' gestartet..."
./start_miner.sh

echo "Fertig! Der Miner läuft jetzt in der Screen-Session 'btc-miner'."
