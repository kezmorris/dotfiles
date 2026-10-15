#!/bin/sh
# macOS only. Copies every new tmux paste buffer to the Mac clipboard.
#
# Programs in tmux (nvim in the devcontainer, over SSH...) copy with an OSC 52
# escape. tmux stores it as a paste buffer, but Terminal.app can't take it
# from there, so this listens in tmux's control mode for "%paste-buffer-changed"
# and runs pbcopy. Started from tmux.conf; one copy runs per tmux server.

sock="${TMUX%%,*}" # the server that started us
[ -n "$sock" ] || exit 0
unset TMUX # or tmux refuses to attach from "inside" itself
tmux() { command tmux -S "$sock" "$@"; }

pidfile="${TMPDIR:-/tmp}/tmux-clipboard-bridge-$(id -u)-$(basename "$sock").pid"
if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then exit 0; fi
echo $$ >"$pidfile"

fifo="${TMPDIR:-/tmp}/tmux-clipboard-bridge-$$.fifo"
mkfifo "$fifo"
exec 3<>"$fifo" # keeps control mode's stdin open without sending it anything
rm -f "$fifo"   # the open descriptor is all that's needed
trap 'rm -f "$pidfile"' EXIT

# The config is read before the first session exists, so wait for one.
for _ in 1 2 3 4 5 6 7 8 9 10; do tmux has-session 2>/dev/null && break; sleep 1; done

while tmux has-session 2>/dev/null; do
  tmux -C attach -f no-output,ignore-size,read-only <&3 2>/dev/null |
    while IFS= read -r line; do
      case $line in
        "%paste-buffer-changed "*) tmux save-buffer -b "${line#* }" - 2>/dev/null | LC_CTYPE=UTF-8 pbcopy ;;
      esac
    done
  sleep 1 # the attached session ended: attach to another if there is one
done
