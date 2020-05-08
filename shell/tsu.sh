#!/usr/bin/bash

# Copyright (c) 2020, Cswl C. https://github.com/cswl
# This software is licensed under the ISC Liscense.
# https://github.com/cswl/tsu/blob/v8/LICENSE.md

### tsu
_TSU_VERSION="8.3.0"
_TSU_DEBUG="false"
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
#ANDROIDSYSTEM_ASROOT_PATHS="/bin:/xbin"

# Some constants that may change in future.
BB_MAGISK="/sbin/.magisk/busybox"

# The first check should to be to if you're actually rooted.

# Options parsing

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
		--version)
			echo "tsu - $_TSU_VERSION"
			exit
			;;
		-h | --help)
			show_usage
			exit
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

		EXP_ENV[PREFIX]="$TERMUX_PREFIX"

		EXP_ENV[TMPDIR]="$ROOT_HOME/.tmp"
		EXP_ENV[LD_PRELOAD]="$LD_PRELOAD"

		NEW_PATH="$TERMUX_PATH"
		ASP="$ANDROIDSYSTEM_PATHS"
		# Should we add /system/* paths:
		# Some Android utilities work. but some break
		[[ -n "$PREPEND_SYSTEM_PATH" ]] && NEW_PATH="$ASP:$NEW_PATH"
		[[ -n "$APPEND_SYSTEM_PATH" ]] && NEW_PATH="$NEW_PATH:$ASP"

		# Android versions prior to 7.0 will break if LD_LIBRARY_PATH is set
		if [[ -n "$LD_LIBRARY_PATH" ]] ; then
			SYS_LIBS="/system/lib64"
			EXP_ENV[LD_LIBRARY_PATH]="$LD_LIBRARY_PATH:$SYS_LIBS"
		fi

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
	# Selection of shell, checked in this order.
	# user defined shell -> user's login shell
	# bash ->  sh
	if [ "$ALT_SHELL" = "system" ]; then
		ROOT_SHELL="/system/bin/sh"
	elif [ -n "$ALT_SHELL" ]; then
		# Expand //usr/ to /usr/
		ALT_SHELL_EXPANDED="${ALT_SHELL/\/usr\//$TERMUX_PREFIX\/}"
		ROOT_SHELL="$ALT_SHELL_EXPANDED"
	elif test -x "$HOME/.termux/shell"; then
		ROOT_SHELL="$(readlink -f -- "$HOME/.termux/shell")"
	elif test -x "$PREFIX/bin/bash"; then
		ROOT_SHELL="$PREFIX/bin/bash"
	else
		ROOT_SHELL="$PREFIX/bin/sh"
	fi
}

root_shell_helper

if [[ "$_TSU_AS_SUDO" == true ]]; then
	SUDO_GID="$(id -g)"
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

SU_BINARY_SEARCH=("/system/xbin/su" "/system/bin/su")

# On some systems with other root methods `/sbin` is inacessible.
if [[ -x "/sbin" ]]; then
	SU_BINARY_SEARCH+=("/sbin/su" "/sbin/bin/su")
else
	SKIP_SBIN=1
fi;

### ----- MAGISK
# shellcheck disable=SC2117
if [[ -z "$SKIP_SBIN" && "$(/sbin/su -v)" == *"MAGISKSU" ]]; then
	# We are on Magisk su
	env_path_helper
		# Android versions prior to 7.0 will break if LD_LIBRARY_PATH is set
		if [[ -n "$LD_LIBRARY_PATH" ]] ; then
			unset LD_LIBRARY_PATH
		fi
	exec "/sbin/su" -c "PATH=$BB_MAGISK env -i $ENV_BUILT $STARTUP_SCRIPT"

##### ----- END MAGISK
else

	# Support for other shells.
	# I dont have other shells to test
	for SU_BINARY in  "${SU_BINARY_SEARCH[@]}" ; do
		if [ -e "$SU_BINARY" ]; then
			# Let's use the system toybox/toolbox for now
			exec "$SU_BINARY" -c "/system/bin/env -i $ENV_BUILT $STARTUP_SCRIPT"
		fi
	done
fi

# We didnt find any su binary
printf -- "No superuser binary detected. \n"
printf -- "Are you rooted? \n"
exit 1
