# dev-test – kurz für Claude

Das hier ist eine Testkiste zum Ausprobieren. Arbeite ganz normal; die Punkte unten sind nur der Rahmen, damit du
weißt, was los ist. Antworten auf Deutsch.

## Was das ist
- Ein Linux-Desktop (Debian, XFCE) in einem Container, bedient im Browser. Kein normaler PC, keine VM.
- Benutzer `jam`, Home ist `/config`, `sudo` geht ohne Passwort.
- Klein bemessen: etwa 1 CPU-Kern zugesichert, höchstens 8 GiB Arbeitsspeicher.

## Grenzen
- **Nur das Home bleibt.** Alles außerhalb (`/etc`, `/usr`, `/opt`, `/tmp`) ist nach jedem Neustart wieder wie im Image.
- **Nach 60 Minuten ohne Nutzung schläft die Kiste ein.** Laufende Programme, Terminals und Sitzungen sind dann weg,
  Dateien im Home bleiben.
- **„Zurücksetzen“ leert das ganze Home** – Dateien, Einstellungen, Anmeldungen, auch die von Claude. Das löst der
  Nutzer von außen aus, nicht du.
- **Netz:** Internet ja, private Netze nein (10.x, 172.16–31.x, 192.168.x). Von außen ist nur das Bild erreichbar;
  ein lokaler Server ist nur im Browser in der Kiste selbst sichtbar.
- **Kein Docker, keine VMs, kein systemd.** Keine GPU.

## So geht es
- Programme mit `sudo apt install <paket>` installieren. Die Kiste merkt sich das und installiert es nach jedem Start
  im Hintergrund wieder (Liste `~/.config/dev-desktop/pakete.txt`); kurz nach dem Start kann ein Programm noch fehlen.
  Meldet `apt install` direkt nach einem Start „Unable to locate package“, einmal `sudo apt update` ausführen.
- Entwicklerwerkzeuge sind nicht vorinstalliert – was fehlt, per `apt` holen.
- Was bleiben soll, gehört ins Home oder in ein Git-Repo, nicht nach `/tmp`.
- Ausprobieren ist hier ausdrücklich erwünscht: Die Kiste lässt sich jederzeit zurücksetzen.

## Lieber nicht
- Nichts Wichtiges nur hier aufbewahren – ein Zurücksetzen löscht es.
- Keine Lösungen bauen, die Docker, eine VM, einen Dienst über den Neustart hinweg oder Zugriff auf private Netze
  brauchen; sag stattdessen, dass das hier nicht geht.
- Lange Jobs nicht unbeaufsichtigt laufen lassen: Schläft die Kiste ein, sind sie weg.

Diese Datei kommt aus dem Image und wird in ein leeres Home kopiert. Eigene Ergänzungen in `~/.claude/CLAUDE.md`
sind nach einem Zurücksetzen wieder weg.
