# The two paths inside 1Password's group container that the run reads, into
# `$agent_socket` and `$app_settings`. Written once and included at render time (ADR
# 0005): the gate refuses on both, P7 declines to rewrite the source remote without the
# socket, and a container a caller could spell differently is a gate that passes while
# the phase it guards skips.
#
# The container identifier is the fact the two paths share, which is why they are
# declared together. A file per path would state it twice.
#
# The ssh configuration names the socket a third time and cannot share this: it is
# `IdentityAgent` in ssh's own syntax, not shell.
#
# Not every caller reads both — P7 wants only the socket — so the unused one is declared
# unused rather than split back out into a second file that would spell the container a
# second time.
onepassword_container="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password"
# shellcheck disable=SC2034
agent_socket="$onepassword_container/t/agent.sock"
# shellcheck disable=SC2034
app_settings="$onepassword_container/Library/Application Support/1Password/Data/settings/settings.json"
