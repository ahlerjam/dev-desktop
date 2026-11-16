# UID 1000 heißt „jam“ (zweiter Name neben „abc“, siehe Dockerfile); Login-Shells ohne Sitzung (kubectl exec) bekommen sonst kein USER.
if [ "$(id -u)" = "1000" ]; then
  export USER=jam LOGNAME=jam
fi
