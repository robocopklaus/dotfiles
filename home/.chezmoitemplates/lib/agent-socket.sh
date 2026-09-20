# The 1Password SSH agent's socket, into `$agent_socket`. Written once and included at
# render time (ADR 0005): the gate refuses on its absence (§2) and P7 declines to rewrite
# the source remote without it (§6.5), and a path those two could spell differently is a
# gate that passes while the phase it guards skips.
#
# The ssh configuration names the same socket a third time and cannot share this: it is
# `IdentityAgent` in ssh's own syntax, not shell.
agent_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
