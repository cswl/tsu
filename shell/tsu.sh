#!/usr/bin/bash

# Copyright (c) 2020, Cswl C. https://github.com/cswl
# This software is licensed under the ISC Liscense.
# https://github.com/cswl/tsu/blob/master/LICENSE.md

### tsu
_TSU_version="8.0.0a+"
_TSU_debug="false"
_TSU_CALL="${BASH_SOURCE[0]##*/}"

## Support for busybox style calling convention
if [[ "$_TSU_CALL" == sudo ]]; then
	_TSU_AS_SUDO=true
fi

# An internal debugging option, which looks like single letter long option. Yeah
if [[ "$1" == "--D" ]]; then
	_TSU_DEBUG=true
	shift
	set -x
fi

show_usage() {
	cat <<EOF
  #SHOW_USAGE_BLOCK
EOF
}

show_usage_sudo() {
	echo "usage: sudo command"
	echo "usage: sudo -u [user] -g [group] command  	"

}

# Defaults in Termux and Android
TERMUX_FS="/data/data/com.termux/files"
TERMUX_PREFIX="$TERMUX_FS/usr"
TERMUX_PATH="$TERMUX_PREFIX/bin:$TERMUX_PREFIX/bin/applets"
ROOT_HOME="$TERMUX_FS/home/.suroot"
ANDROIDSYSTEM_PATHS="/system/bin:/system/xbin"
ANDROIDSYSTEM_ASROOT_PATHS="/bin:/xbin"

# Some constants that may change in future.
BB_MAGISK="/sbin/.magisk/busybox"

# The first check should to be to if you're actually rooted.

# Options parsing

# Default values of arguments

# Loop through arguments and process them
if [[ "$_TSU_AS_SUDO" == true ]]; then
	# Handle cases where people do `sudo su` like what
	if [[ "$1" == "su" ]]; then
		unset _TSU_AS_SUDO
	fi
fi

if [[ -z "$_TSU_AS_SUDO" ]]; then
	for arg in "$@"; do
		case $arg in
		-p | --syspre)
			PREPEND_SYSTEM_PATH=true
			shift
			;;
		-a | --sysadd)
			APPEND_SYSTEM_PATH=true
			shift
			;;
		-s | --shell)
			ALT_SHELL="$2"
			shift
			shift
			;;
		-h | --help)
			show_usage
			shift
			;;

		*)
			OTHER_ARGUMENTS+=("$1")
			shift
			;;
		esac
	done

	SWITCH_USER="$1"
fi

declare -A EXP_ENV

env_path_helper() {

	# This is the default behavior of linux.
	if [[ -z "$SWITCH_USER" ]]; then
		NEW_HOME="$ROOT_HOME"
		NEW_TMP="$ROOT_HOME/.tmp"

		EXP_ENV[PREFIX]="$TERMUX_PREFIX"

		EXP_ENV[TMPDIR]="$ROOT_HOME/.tmp"
		EXP_ENV[LD_PRELOAD]="$LD_PRELOAD"

		NEW_PATH="$TERMUX_PATH"
		ASP="$ANDROIDSYSTEM_PATHS"
		# Should we add /system/* paths:
		# Some Android utilities work. but some break
		[[ ! -z "$PREPEND_SYSTEM_PATH" ]] && NEW_PATH="$ASP:$NEW_PATH"
		[[ ! -z "$APPEND_SYSTEM_PATH" ]] && NEW_PAT="$NEW_PATH:$ASP"
	else
		# Other uid in the system cannot run Termux binaries
		NEW_HOME="/"
		NEW_PATH="$ANDROIDSYSTEM_PATHS"

	fi

	# We create a new environment cause the one on normal Termux is polluted with startup scripts
	EXP_ENV[PATH]="$NEW_PATH"
	EXP_ENV[HOME]="$NEW_HOME"
	EXP_ENV[TERM]="xterm-256color"

	[[ -z "$_TSU_DEBUG" ]] || set +x
	## Android specific exports: Need more testing.
	EXP_ENV[ANDROID_ROOT]="$ANDROID_ROOT"
	EXP_ENV[ANDROID_DATA]="$ANDROID_DATA"

	ENV_BUILT=""

	for key in "${!EXP_ENV[@]}"; do
		ENV_BUILT="$ENV_BUILT $key=${EXP_ENV[$key]} "
	done

	[[ -z "$_TSU_DEBUG" ]] || set -x
}

root_shell_helper() {
	# Select shell
	if [ -n "$USER_SHELL" ]; then
		# Expand //usr/ to /usr/
		USER_SHELL_EXPANDED=$(echo "$USER_SHELL" | sed "s|^//usr/|$TERMUX_PREFIX/|")
		ROOT_SHELL="$USER_SHELL_EXPANDED"
	elif [ "$USER_SHELL" = "system" ]; then
		ROOT_SHELL="/system/bin/sh"
		# Check if user has set a login shell
	elif test -x "$HOME/.termux/shell"; then
		ROOT_SHELL="$(readlink -f -- "$HOME/.termux/shell")"
		# Or at least installed bash
	elif test -x "$PREFIX/bin/bash"; then
		ROOT_SHELL="$PREFIX/bin/bash"
		# Oh well fallback to
	else
		ROOT_SHELL="$PREFIX/bin/ash"
	fi
}

root_shell_helper

if [[ "$_TSU_AS_SUDO" == true ]]; then
	SUDO_GID="$(id -g)"
	SUDO_COMMAND=/bin/bash
	SUDO_USER="$(id -un)"
	if [[ -z "$1" ]]; then
		show_usage_sudo
		exit 1
	fi
	CMD_ARGS=$(printf '%q ' "$@")
	STARTUP_SCRIPT="LD_PRELOAD=$LD_PRELOAD SUDO_GID=$SUDO_GID SUDO_USER=$SUDO_USER  $CMD_ARGS"
else
	STARTUP_SCRIPT="$ROOT_SHELL"
fi

### ----- MAGISK
if [[ "$(/sbin/su -v)" == "20"*"MAGISKSU" ]]; then
	# We are on fairly recent Magisk version
	# Build a script

	env_path_helper
	exec "/sbin/su" -c "PATH=$BB_MAGISK env -i $ENV_BUILT $STARTUP_SCRIPT"

##### ----- END MAGISK
else

	# Support for other shells.
	# I dont have other shells to test
	for SU_BINARY in '/su/bin/su' '/sbin/su' '/system/xbin/su' '/system/bin/su'; do
		if [ -e "$s" ]; then
			# The --preserve-enivorment is used to copy variables
			# Since we would have to detect busybox and others
			exec "$SU_BINARY" -c "LD_PRELOAD=$LD_PRELOAD $STARTUP_SCRIPT"
		fi
	done
fi

# We didnt find any su binary
printf -- "No superuser binary detected. \n"
printf -- "Are you rooted? \n"
exit 1
