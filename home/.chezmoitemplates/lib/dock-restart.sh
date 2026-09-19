# §6.4's one restart rule, shared by the two managers of `com.apple.dock`: the defaults
# table (60) and the layout (61). Two managers of one domain is accepted, because the
# layout genuinely cannot be flat `domain/key/type/value`. Two restarts of one application
# is not — and the restart has to come *after* the layout is written rather than between
# the two steps, or `dockutil`'s changes would need a second one anyway.
#
# So 60 records its change here and 61 performs the single `killall Dock` at the end of
# P6. This file carries the one fact the two must agree on and nothing else; a pair of
# wrapper functions around `touch` and `killall` would be a framework for two call sites.
#
# The request outlives the process rather than the run, which is the honest cost of the
# two steps being two `run_onchange_` scripts: if 60 runs in an apply where 61's content
# did not change, the restart is carried to 61's next run rather than lost. A Dock restart
# is idempotent and macOS brings it straight back, so a deferred one costs a flicker.
dock_restart_request="${TMPDIR:-/tmp}/dotfiles-dock-restart"
