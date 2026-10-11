# The application bundles a cask names, read from `brew info --cask --json=v2` on stdin
# and printed one per line, `.app` included. Asked of Homebrew rather than guessed from the
# cask's token: `microsoft-teams` and `telegram-desktop` alone would defeat guessing.
#
# A cask names its application in an `app` artifact, the `target` a relocated one is moved
# to, or an `uninstall` path. Every `.app` string anywhere in the artifacts covers all
# three under one rule rather than three. A cask that ships a `pkg` may name its bundle
# nowhere, because the installer package's receipt is what knows — and a receipt exists
# only on a machine that installed it, so that rule is `drift`'s alone and not here.
cask_bundles() {
  jq -r '[.casks[].artifacts | .. | strings] | .[] | select(endswith(".app"))' | sed 's|.*/||'
}
