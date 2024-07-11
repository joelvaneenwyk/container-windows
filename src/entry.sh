#!/usr/bin/env bash
# shellcheck disable=SC1091

set -Eeuo pipefail

: "${BOOT_MODE:="windows"}"

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we are running in Docker container right now
if [ -f "/.dockerenv" ] && [ -d "/run" ] && [ -e "/run/entry.sh" ]; then
  DOCKER_WINDOWS_SCRIPTS_PATH="/run"
elif [ -d "$CURRENT_SCRIPT_DIR" ]; then
  DOCKER_WINDOWS_SCRIPTS_PATH="$DIR"
else
  exit 55
fi

export APP="Windows"
export SUPPORT="https://github.com/joelvaneenwyk/container-windows"

cd "$DOCKER_WINDOWS_SCRIPTS_PATH" || exit 56

. "$DOCKER_WINDOWS_SCRIPTS_PATH/reset.sh"      # Initialize system
. "$DOCKER_WINDOWS_SCRIPTS_PATH/define.sh"     # Define versions
. "$DOCKER_WINDOWS_SCRIPTS_PATH/mido.sh"       # Download code
. "$DOCKER_WINDOWS_SCRIPTS_PATH/install.sh"    # Run installation
. "$DOCKER_WINDOWS_SCRIPTS_PATH/disk.sh"       # Initialize disks
. "$DOCKER_WINDOWS_SCRIPTS_PATH/display.sh"    # Initialize graphics
. "$DOCKER_WINDOWS_SCRIPTS_PATH/network.sh"    # Initialize network
. "$DOCKER_WINDOWS_SCRIPTS_PATH/samba.sh"      # Configure samba
. "$DOCKER_WINDOWS_SCRIPTS_PATH/boot.sh"       # Configure boot
. "$DOCKER_WINDOWS_SCRIPTS_PATH/proc.sh"       # Initialize processor
. "$DOCKER_WINDOWS_SCRIPTS_PATH/power.sh"      # Configure shutdown
. "$DOCKER_WINDOWS_SCRIPTS_PATH/config.sh"     # Configure arguments

trap - ERR

version=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1 | awk '{ print $NF }')
info "Booting ${APP}${BOOT_DESC} using QEMU v$version..."

{ qemu-system-x86_64 ${ARGS:+ $ARGS} >"$QEMU_OUT" 2>"$QEMU_LOG"; rc=$?; } || :
(( rc != 0 )) && error "$(<"$QEMU_LOG")" && exit 15

terminal
( sleep 10; boot ) &
tail -fn +0 "$QEMU_LOG" 2>/dev/null &
cat "$QEMU_TERM" 2> /dev/null | tee "$QEMU_PTY" &
wait $! || :

sleep 1 & wait $!
[ ! -f "$QEMU_END" ] && finish 0
