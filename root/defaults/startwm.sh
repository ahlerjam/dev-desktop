#!/bin/bash
# Sitzungsstart des Dev-Desktops (ersetzt /defaults/startwm.sh aus webtop:debian-xfce).

# Der Prozess läuft mit UID 1000; die heißt im Image „jam“ (zweiter Name neben „abc“, siehe Dockerfile).
export USER=jam LOGNAME=jam

# Ohne Anmeldemanager setzt niemand die Desktop-Umgebung. Electron (Claude Desktop) und Chrome erkennen dann keinen
# Schlüsselbund, nehmen den Speicher „basic_text“ und Claude Desktop verwirft die Anmeldung („safeStorage not
# available, tokens will not persist“, Log vom 16.11.). Mit XFCE wählen sie gnome-libsecret (Electron-Doku safeStorage);
# den Schlüsselbund dazu entsperrt /usr/local/bin/desktop-sitzung.
export XDG_CURRENT_DESKTOP=XFCE

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

# Zweite Einrichtungsrunde (16.11.), einmalig – auch für ein Home, das schon vor dieser Version angelegt wurde:
#   - Leiste mit Startern (überschreibt die bisherige Leisten-Einstellung einmal),
#   - Schreibtisch-Symbole: breitere Beschriftung, nicht mit „…“ abschneiden (GTK-Stil von xfdesktop).
if [ ! -e "${HOME}"/.config/dev-desktop-eingerichtet-2 ]; then
  leiste="${HOME}"/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
  cp /defaults/xfce/xfce4-panel.xml "${leiste}"
  nr=11
  for app in xfce4-terminal chromium google-chrome claude-desktop; do
    if [ -f /usr/share/applications/${app}.desktop ]; then
      mkdir -p "${HOME}"/.config/xfce4/panel/launcher-${nr}
      cp /usr/share/applications/${app}.desktop "${HOME}"/.config/xfce4/panel/launcher-${nr}/
    else
      sed -i -e "/plugin-${nr}\"/d" -e "/<value type=\"int\" value=\"${nr}\"\/>/d" "${leiste}"
    fi
    nr=$((nr + 1))
  done
  mkdir -p "${HOME}"/.config/gtk-3.0
  if ! grep -qs 'XfdesktopIconView' "${HOME}"/.config/gtk-3.0/gtk.css; then
    cat >> "${HOME}"/.config/gtk-3.0/gtk.css <<'CSS'
/* Dev-Desktop: Beschriftung der Schreibtisch-Symbole breiter und ungekürzt */
XfdesktopIconView.view {
  -XfdesktopIconView-ellipsize-icon-labels: 0;
  -XfdesktopIconView-cell-text-width-proportion: 2.6;
}
CSS
  fi
  touch "${HOME}"/.config/dev-desktop-eingerichtet-2
fi

# Das Home liegt auf NFS und überlebt das Einschlafen; die Browser-Sperrdateien zeigen dann auf einen Pod,
# den es nicht mehr gibt ("Profil wird bereits verwendet").
rm -f "${HOME}"/.config/google-chrome/Singleton* "${HOME}"/.config/chromium/Singleton*

exec dbus-launch --exit-with-session /usr/local/bin/desktop-sitzung > /dev/null 2>&1
