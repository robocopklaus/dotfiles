# The run's root privilege, kept warm for the calling script. Two reasons, and the gate
# is the only call site that has just the second: each chezmoi script is a separate
# process, so a privilege acquired in one cannot be adopted in another — and within
# one script, an installer that downloads for minutes before it asks for root can outlive
# the timestamp that was taken for it.
sudo -v
# The loop runs in its own process group with the script's output closed to it. Both
# matter on the way out: `kill` reaches the loop but not the `sleep` it is blocked in, and
# that orphan would hold the inherited stdout open — so whoever reads this script's output
# waits for a pipe the script is no longer writing to, for as long as a minute after it
# exited. Signalling the group takes the sleep with it; closing the descriptors means an
# orphan that outlives the signal anyway is holding nothing.
set -m
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done >/dev/null 2>&1 &
keepalive=$!
set +m
trap 'kill -- "-$keepalive" 2>/dev/null || kill "$keepalive" 2>/dev/null || true' EXIT
