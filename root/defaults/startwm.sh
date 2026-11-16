#!/bin/bash
# Sitzungsstart des Dev-Desktops (ersetzt /defaults/startwm.sh aus webtop:debian-xfce).

# Der Prozess läuft mit UID 1000; die heißt im Image „jam“ (zweiter Name neben „abc“, siehe Dockerfile).
export USER=jam LOGNAME=jam

# Voreinstellungen nur beim allerersten Start ins Home kopieren (wie im Original)
if [ ! -d "${HOME}"/.config/xfce4/xfconf/xfce-perchannel-xml ]; then
  mkdir -p "${HOME}"/.config/xfce4/xfconf/xfce-perchannel-xml
  cp /defaults/xfce/* "${HOME}"/.config/xfce4/xfconf/xfce-perchannel-xml/
fi

# Starter auf den Schreibtisch, einmalig
if [ ! -e "${HOME}"/.config/dev-desktop-eingerichtet ]; then
  mkdir -p "${HOME}"/Desktop "${HOME}"/Projekte
  for app in claude-desktop google-chrome chromium xfce4-terminal; do
    if [ -f /usr/share/applications/${app}.desktop ]; then
      cp /usr/share/applications/${app}.desktop "${HOME}"/Desktop/
      chmod +x "${HOME}"/Desktop/${app}.desktop
    fi
  done
  touch "${HOME}"/.config/dev-desktop-eingerichtet
fi

# Das Home liegt auf NFS und überlebt das Einschlafen; die Browser-Sperrdateien zeigen dann auf einen Pod,
# den es nicht mehr gibt ("Profil wird bereits verwendet").
rm -f "${HOME}"/.config/google-chrome/Singleton* "${HOME}"/.config/chromium/Singleton*

exec dbus-launch --exit-with-session /usr/local/bin/desktop-sitzung > /dev/null 2>&1
