#!/bin/sh
# Points git's own colours at the sixteen slots. Idempotent, and it never
# overwrites a key you have already set: run with --force to overrule that.
set -e
FORCE=0
[ "$1" = "--force" ] && FORCE=1
set_if_absent() {
  if [ "$FORCE" -eq 0 ] && git config --global --get "$1" >/dev/null 2>&1; then
    echo "  kept    $1 = $(git config --global --get "$1")"
  else
    git config --global "$1" "$2"; echo "  set     $1 = $2"
  fi
}
echo "git colours:"
set_if_absent color.ui auto
set_if_absent color.diff.new green
set_if_absent color.diff.old red
set_if_absent color.diff.frag cyan
set_if_absent color.diff.meta yellow
set_if_absent color.diff.commit "brightred"
set_if_absent color.status.added green
set_if_absent color.status.changed yellow
set_if_absent color.status.untracked "brightblack"
set_if_absent color.status.branch "green"
set_if_absent color.branch.current "green"
set_if_absent color.branch.remote "cyan"
set_if_absent color.decorate.branch "green"
set_if_absent color.decorate.HEAD "brightred"
set_if_absent color.decorate.tag "magenta"
# delta, if it is installed: its "ansi" syntax theme draws with the slots
if command -v delta >/dev/null 2>&1; then
  set_if_absent delta.syntax-theme ansi
  set_if_absent delta.hunk-header-style "line-number syntax"
  set_if_absent delta.line-numbers true
fi
