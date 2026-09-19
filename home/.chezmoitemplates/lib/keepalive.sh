# The run's root privilege, kept warm for the calling script. Each chezmoi script is a
# separate process, so the privilege the gate acquired in P2 cannot be adopted (§3), and
# installers prompt at unpredictable points during a run.
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done &
keepalive=$!
trap 'kill "$keepalive" 2>/dev/null || true' EXIT
