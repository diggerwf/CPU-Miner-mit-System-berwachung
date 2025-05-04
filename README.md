CPU-Miner mit Systemüberwachung
================================

Dieses Projekt enthält ein Bash-Skript, das automatisch einen CPU-basierten Miner (SHA256d) auf einem Linux-System installiert, konfiguriert und startet. Zusätzlich wird Netdata installiert, um die Systemleistung in Echtzeit zu überwachen.

Funktionen
---------
- Systemaktualisierung und -konfiguration
- Abhängigkeiten installieren
- Quellcode des Miners klonen und kompilieren
- Miner in einer Screen-Session starten
- Netdata zur Systemüberwachung installieren

Nutzung
-------
1. Das Repository klonen:
   git clone https://github.com/diggerwf/CPU-Miner-mit-System-berwachung/blob/main/install_miner.sh

2. In das Verzeichnis wechseln:
   cd CPU-Miner-mit-System-berwachung

3. Das Installationsskript ausführbar machen:
   chmod +x install_miner.sh

4. Das Skript ausführen:
   ./install_miner.sh

Hinweis:
---------
Vor der Ausführung solltest du die Platzhalter im Skript `install_miner.sh` anpassen:

- Ersetze `DEINE_WALLET_ADRESSE` durch deine tatsächliche Wallet-Adresse.
- Ersetze `stratum+tcp://pooladresse:port` durch die Adresse deines Mining-Pools.

Das Skript startet den Miner automatisch in einer Screen-Session namens `btc-miner`. Du kannst die Session mit folgendem Befehl wieder aufnehmen:

   screen -r btc-miner

Um die Session zu beenden:

   screen -S btc-miner -X quit

Hinweise
--------
- Das Skript setzt voraus, dass du Ubuntu oder eine andere Debian-basierte Distribution verwendest.
- Für andere Distributionen könnten Anpassungen notwendig sein.
- Stelle sicher, dass dein System ausreichend Ressourcen für das Mining hat.

Lizenz
------
Dieses Projekt steht unter MIT-Lizenz / frei verwendbar.
