#!/bin/sh
# start | stop | status | toggle for the flashing cursor.
#
# launchd owns the process rather than a PID file: a PID file and a KeepAlive
# agent would fight, with `stop` killing a process launchd immediately restarts.
LABEL=com.jackandjill.cursorcycle
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"
case "${1:-toggle}" in
  start)  launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null && echo "cycling" || echo "already cycling" ;;
  stop)   launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null && echo "stopped" || echo "not running" ;;
  status) launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 && echo "cycling" || echo "stopped" ;;
  toggle) if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then "$0" stop; else "$0" start; fi ;;
  *) echo "usage: jj-cursor.sh start|stop|status|toggle" >&2; exit 2 ;;
esac
