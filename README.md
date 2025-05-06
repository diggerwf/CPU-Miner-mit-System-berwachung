CPU-Miner mit Systemüberwachung

================================

Dieses Projekt enthält ein Bash-Skript, das automatisch einen CPU-basierten Miner (SHA256d) auf einem Linux-System installiert, konfiguriert und startet. Zusätzlich wird Netdata installiert, die Systemleistung in Echtzeit zu überwachen.

Funktionen

Systemaktualisierung und -konfiguration
Abhängigkeiten installieren
Quellcode des Miners klonen und kompilieren
Miner in einer Screen-Session starten
Netdata zur Systemüberwachung installieren

Nutzung

Das Repository klonen:
   git clone https://github.com/diggerwf/CPU-Miner-mit-System-berwachung.git
Copy
In das Verzeichnis wechseln:
   cd CPU-Miner-mit-System-berwachung
Copy
Das Installationsskript ausführbar machen:
   chmod +x install_miner.sh
Copy
Das Skript ausführen:
   ./install_miner.sh
Copy

Die Datei start_miner.sh hat folgende Optionen:

-w : Löscht gespeicherte Wallet- und Pool-Daten
-i : Fragt Wallet-Adresse und Pool erneut ab
-wi: Löscht gespeicherte Daten und fordert neu an

Beispiel:

   ./start_miner.sh -w
   ./start_miner.sh -i
   ./start_miner.sh -wi
