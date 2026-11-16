# dev-desktop

Zwei Linux-Desktops als Container-Images: Debian 13 + XFCE, bedient im Browser
(Basis [linuxserver/webtop](https://docs.linuxserver.io/images/docker-webtop/) `debian-xfce`, Selkies).
Multi-Arch (amd64 + arm64). Ein Dockerfile, zwei Ziele:

| Ziel | Image | Inhalt |
|---|---|---|
| `test` | `ghcr.io/ahlerjam/dev-desktop-test` | Google Chrome, Chromium, Claude Desktop, Claude Code, Optik (Arc-Dark, Papirus, Inter) |
| `desktop` | `ghcr.io/ahlerjam/dev-desktop` | wie `test`, dazu git/gh, Node.js, Python, Build-Werkzeuge |

- Bau: GitHub Actions (`.github/workflows/build.yml`) bei jedem Push auf `main` oder von Hand; die Digests stehen in der
  Zusammenfassung des Laufs.
- Neue Programme: ins `Dockerfile`, pushen, Digest dort eintragen, wo das Image läuft.
- Der Desktop hat keine eigene Anmeldung und passwortloses sudo: nur hinter einem Zugangsschutz betreiben.
- Die Browser nutzen ihre Sandbox nur, wenn der Container ohne seccomp-Filter läuft und der Host User-Namespaces erlaubt;
  sonst starten die Wrapper sie mit `--no-sandbox`.
