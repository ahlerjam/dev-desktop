# Zwei Linux-Desktops im Browser: Debian 13 + XFCE (linuxserver webtop / Selkies), Multi-Arch (amd64 + arm64).
# Zwei Ziele aus einem Dockerfile, gebaut per GitHub Actions (.github/workflows/build.yml):
#   test     -> ghcr.io/ahlerjam/dev-desktop-test : blanke Kiste, nur Google Chrome + Chromium (aus webtop) + Optik
#   desktop  -> ghcr.io/ahlerjam/dev-desktop      : wie test, dazu Claude Desktop, Claude Code und Entwicklerwerkzeuge
# Programme liegen bewusst im Image und nicht im Home: ein Home auf Netzspeicher kann zwischen arm64 und x86 wandern.
# Was zur Laufzeit per apt installiert wird, ist nach dem nächsten Neustart weg.

# ---------------------------------------------------------------------------------------------
FROM lscr.io/linuxserver/webtop:debian-xfce AS test

ARG DEBIAN_FRONTEND=noninteractive

RUN \
  echo "**** Google Chrome (amd64 und arm64 direkt von Google) ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates curl && \
  curl -fsSLo /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_$(dpkg --print-architecture).deb" && \
  apt-get install -y --no-install-recommends /tmp/chrome.deb && \
  echo "**** Optik: Arc-Dark, Papirus, Inter, JetBrains Mono, Whisker-Menü ****" && \
  apt-get install -y --no-install-recommends \
    arc-theme \
    fonts-inter \
    fonts-jetbrains-mono \
    fonts-noto-color-emoji \
    locales \
    papirus-icon-theme \
    xfce4-whiskermenu-plugin && \
  sed -i \
    -e 's#"ThemeName" type="string" value="[^"]*"#"ThemeName" type="string" value="Arc-Dark"#' \
    -e 's#"IconThemeName" type="string" value="[^"]*"#"IconThemeName" type="string" value="Papirus-Dark"#' \
    -e 's#<property name="FontName" type="empty"/>#<property name="FontName" type="string" value="Inter 10"/>#' \
    -e 's#<property name="MonospaceFontName" type="empty"/>#<property name="MonospaceFontName" type="string" value="JetBrains Mono 10"/>#' \
    -e 's#<property name="Antialias" type="empty"/>#<property name="Antialias" type="int" value="1"/>#' \
    -e 's#<property name="Hinting" type="empty"/>#<property name="Hinting" type="int" value="1"/>#' \
    -e 's#<property name="HintStyle" type="empty"/>#<property name="HintStyle" type="string" value="hintslight"/>#' \
    /defaults/xfce/xsettings.xml && \
  sed -i \
    -e 's#"theme" type="string" value="[^"]*"#"theme" type="string" value="Arc-Dark"#' \
    -e 's#"title_font" type="string" value="[^"]*"#"title_font" type="string" value="Inter Semi-Bold 10"#' \
    -e 's#"workspace_count" type="int" value="[^"]*"#"workspace_count" type="int" value="2"#' \
    /defaults/xfce/xfwm4.xml && \
  grep -q 'Arc-Dark' /defaults/xfce/xsettings.xml && grep -q 'Inter 10' /defaults/xfce/xsettings.xml && \
  grep -q 'Arc-Dark' /defaults/xfce/xfwm4.xml && \
  echo "**** Chrome wie das webtop-Chromium starten (Sandbox nur, wenn seccomp aus ist) ****" && \
  sed -i 's#^Exec=/usr/bin/google-chrome-stable#Exec=/usr/local/bin/wrapped-chrome#g' /usr/share/applications/google-chrome.desktop && \
  grep -q 'wrapped-chrome' /usr/share/applications/google-chrome.desktop && \
  echo "**** aufräumen ****" && \
  apt-get autoclean && \
  rm -rf /config/.cache /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Eigene Dateien: Sitzungsstart (Starter, Sperrdateien, Keyring falls vorhanden), Leiste, Chrome-Wrapper, Hintergrundbilder
COPY /root /

# Benutzer heißt „jam“ statt „abc“. Das Basis-Image verdrahtet „abc“ fest in allen Startskripten (s6-setuidgid abc,
# usermod … abc), deshalb bleibt „abc“ bestehen und „jam“ ist ein zweiter Name für dieselbe UID 1000 (PUID/PGID im
# Deployment). Er steht in passwd/group VOR „abc“, damit die Auflösung UID → Name „jam“ liefert (Terminal, whoami, sudo).
# Gleiche Gruppen wie „abc“, damit sudo ohne Passwort weiter geht. Hintergrundbild: blau = Dev-Desktop, orange = dev-test.
RUN \
  groupadd -g 1000 jam && \
  useradd -u 1000 -g 1000 -M -d /config -s /bin/bash -c jam -G "$(id -Gn abc | tr ' ' '\n' | grep -vx abc | paste -sd,)" jam && \
  for f in /etc/passwd /etc/group; do \
    zeile="$(grep '^jam:' "$f")" && \
    sed -i -e '/^jam:/d' "$f" && \
    sed -i -e "/^abc:/i ${zeile}" "$f"; \
  done && \
  [ "$(getent passwd 1000 | cut -d: -f1)" = jam ] && [ "$(getent group 1000 | cut -d: -f1)" = jam ] && \
  id jam && id abc && \
  ln -sf test.png /usr/share/backgrounds/dev-desktop/hintergrund.png && \
  test -s /usr/share/backgrounds/dev-desktop/hintergrund.png

EXPOSE 3000
VOLUME /config

# ---------------------------------------------------------------------------------------------
FROM test AS desktop

ARG DEBIAN_FRONTEND=noninteractive
# Fingerabdruck des Anthropic-Signaturschlüssels (Doku code.claude.com: desktop-linux und setup)
ARG ANTHROPIC_FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE

RUN \
  echo "**** Anthropic-Repos (Claude Desktop + Claude Code) ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends gnupg && \
  install -d -m 0755 /etc/apt/keyrings && \
  curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc && \
  curl -fsSLo /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc && \
  for k in /usr/share/keyrings/claude-desktop-archive-keyring.asc /etc/apt/keyrings/claude-code.asc; do \
    fpr="$(gpg --show-keys --with-colons "$k" | awk -F: '$1=="fpr"{print $10; exit}')"; \
    [ "$fpr" = "$ANTHROPIC_FPR" ] || { echo "Falscher Schlüssel in $k: $fpr"; exit 1; }; \
  done && \
  echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    > /etc/apt/sources.list.d/claude-desktop.list && \
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" \
    > /etc/apt/sources.list.d/claude-code.list && \
  apt-get update && \
  echo "**** Claude Desktop (ohne QEMU: Cowork braucht /dev/kvm, das gibt es im Pod nicht), Claude Code ****" && \
  apt-get install -y --no-install-recommends \
    claude-desktop \
    claude-code \
    gnome-keyring \
    libayatana-appindicator3-1 \
    libsecret-1-0 \
    libsecret-tools \
    seahorse \
    socat && \
  echo "**** Entwicklerwerkzeuge (nodejs kommt aus der Paketquelle des Basis-Images und enthält npm; das Debian-Paket npm kollidiert damit) ****" && \
  apt-get install -y --no-install-recommends \
    build-essential \
    fd-find \
    gh \
    git \
    htop \
    jq \
    less \
    nano \
    nodejs \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    tmux \
    vim \
    wget && \
  echo "**** Kontrolle ****" && \
  node --version && npm --version && claude --version && dpkg -s claude-desktop | grep '^Version' && \
  echo "**** aufräumen ****" && \
  apt-get autoclean && \
  rm -rf /config/.cache /var/lib/apt/lists/* /var/tmp/* /tmp/*

RUN ln -sf desktop.png /usr/share/backgrounds/dev-desktop/hintergrund.png && test -s /usr/share/backgrounds/dev-desktop/hintergrund.png

# Claude Code aktualisiert sich nicht selbst (apt-Paket); neue Versionen kommen mit einem neuen Image (Workflow erneut laufen lassen).
ENV DISABLE_AUTOUPDATER=1
