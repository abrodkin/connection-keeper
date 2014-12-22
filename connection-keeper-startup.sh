#! /bin/sh
### BEGIN INIT INFO
# Provides:          connection-keeper
# Required-Start:    $all
# Required-Stop:
# Should-Start:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Manages connection-keeper script
# Description:       Manages connection-keeper script
### END INIT INFO

PATH=$PATH:/home/pi/connection-keeper
CMD=connection-keeper.sh

case "$1" in
    start)
        echo "Starting connection-keeper..."
        $CMD | logger -t connection-keeper &
        ;;
    restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
        ;;
    stop)
        echo "Stopping connection-keeper..."
        killall $CMD
        ;;
    *)
        echo "Usage: $0 start|stop" >&2
        exit 3
        ;;
esac

