#!/usr/bin/bash

# Copyright (c) 2020, Cswl C. https://github.com/cswl
# This software is licensed under the ISC Liscense.
# https://github.com/cswl/tsu/blob/v8/LICENSE.md

### tsu
_TSU_VERSION="8.4.1"
_TSU_CALL="${BASH_SOURCE[0]##*/}"

## Support for busybox style calling convention
if [[ "$_TSU_CALL" == "sudo" ]]; then
	_TSU_AS_SUDO=true
fi

log_DEBUG() { __debug_wrapper() { :; }; }

gather_debug_info() {
	echo "Environment: "
	env
	echo "============================"
	dpkg --print-architecture
	echo "Android version:"
	getprop ro.build.version.release
	echo "Android device:"
	getprop ro.product.manufacturer
	getprop ro.product.model
	uname -a

} >>"$LOG_FILE"

# Allow debugging with a long option
if [[ "$1" == '--dbg' ]]; then
	_TSU_DEBUG=true
	printf -v LOG_FILE "%(%Y%m%d)T"
	LOG_FILE="./tsu_debug_$LOG_FILE"
	gather_debug_info
	set -x
	shift
fi
show_usage() {
	cat <<"EOF"
  #SHOW_USAGE_BLOCK
EOF
}

show_usage_sudo() {
	echo "usage: sudo command"
	echo "usage: sudo -u USER command "
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
log_DEBUG TSU_AS_SUDO
if [[ "$_TSU_AS_SUDO" == true ]]; then
	# Handle cases where people do `sudo su`
	if [[ "$1" == "su" ]]; then
		unset _TSU_AS_SUDO
	fi
	for arg in "$@"; do
		case $arg in
		-u | --user)
			SWITCH_USER="$2"
			shift
			shift
			;;
		esac
	done

fi

log_DEBUG _TSU_AS_SUDO
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
			POS_ARGS+=("$1")
			shift
			;;
		esac
	done

	SWITCH_USER="${POS_ARGS[0]}"
fi

declare -A EXP_ENV

env_path_helper() {

	# This is the default behavior of linux.

	log_DEBUG "${FUNCNAME[0]}"

	log_DEBUG SWITCH_USER
	if [[ -z "$SWITCH_USER" ]]; then
		NEW_HOME="$ROOT_HOME"

		EXP_ENV[PREFIX]="$TERMUX_PREFIX"

		EXP_ENV[TMPDIR]="$ROOT_HOME/.tmp"
		EXP_ENV[LD_PRELOAD]="$LD_PRELOAD"

		log_DEBUG _TSU_AS_SUDO
		if [[ "$_TSU_AS_SUDO" == true ]]; then
			# sudo copies PATH variable, so most user binaries can run as root
			# tested with `sudo env` version 1.8.31p1
			NEW_PATH="$PATH"
			SUDO_GID="$(id -g)"
			SUDO_USER="$(id -un)"
			EXP_ENV[SUDO_GID]=$SUDO_GID
			EXP_ENV[SUDO_USER]=$SUDO_USER
		else
			NEW_PATH="$TERMUX_PATH"
			ASP="$ANDROIDSYSTEM_PATHS"
			# Should we add /system/* paths:
			# Some Android utilities work. but some break
			log_DEBUG "PREPEND_SYSTEM_PATH"
			[[ -n "$PREPEND_SYSTEM_PATH" ]] && NEW_PATH="$ASP:$NEW_PATH"
			log_DEBUG "APPEND_SYSTEM_PATH"
			[[ -n "$APPEND_SYSTEM_PATH" ]] && NEW_PATH="$NEW_PATH:$ASP"
		fi
		# Android versions prior to 7.0 will break if LD_LIBRARY_PATH is set
		log_DEBUG "LD_LIBRARY_PATH"
		if [[ -n "$LD_LIBRARY_PATH" ]]; then
			SYS_LIBS="/system/lib64"
			EXP_ENV[LD_LIBRARY_PATH]="$LD_LIBRARY_PATH:$SYS_LIBS"
		fi

	else
		# Other uid in the system cannot run Termux binaries
		NEW_HOME="/"
		NEW_PATH="$ANDROIDSYSTEM_PATHS"

	fi

	# We create a new environment cause the one on the
	# user Termux enviroment may be polluted with startup scripts
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

	# Creat root $HOME if it doesnt exsists yet
	[[ -d "$ROOT_HOME" ]] || mkdir "$ROOT_HOME"
}

root_shell_helper() {
	log_DEBUG "${FUNCNAME[0]}"

	if [[ -n "$SWITCH_USER" ]]; then
		ROOT_SHELL="/system/bin/sh"
		return
	fi
	# Selection of shell, checked in this order.
	# user defined shell -> user's login shell
	# bash ->  sh
	log_DEBUG "ALT_SHELL"
	if [[ "$ALT_SHELL" == "system" ]]; then
		ROOT_SHELL="/system/bin/sh"
	elif [[ -n "$ALT_SHELL" ]]; then
		# Expand //usr/ to /usr/
		ALT_SHELL_EXPANDED="${ALT_SHELL/\/usr\//$TERMUX_PREFIX\/}"
		ROOT_SHELL="$ALT_SHELL_EXPANDED"
	elif [[ -x "$HOME/.termux/shell" ]]; then
		ROOT_SHELL="$(readlink -f -- "$HOME/.termux/shell")"
	elif [[ -x "$PREFIX/bin/bash" ]]; then
		ROOT_SHELL="$PREFIX/bin/bash"
	else
		ROOT_SHELL="$PREFIX/bin/sh"
	fi
}

log_DEBUG _TSU_AS_SUDO
if [[ "$_TSU_AS_SUDO" == true ]]; then
	if [[ -z "$1" ]]; then
		show_usage_sudo
		exit 1
	fi
	CMD_ARGS=$(printf '%q ' "$@")
	env_path_helper
	STARTUP_SCRIPT="$CMD_ARGS"
else
	root_shell_helper
	env_path_helper

	STARTUP_SCRIPT="$ROOT_SHELL"
fi

SU_BINARY_SEARCH=("/system/xbin/su" "/system/bin/su")

# On some systems with other root methods `/sbin` is inacessible.
if [[ -x "/sbin" ]]; then
	SU_BINARY_SEARCH+=("/sbin/su" "/sbin/bin/su")
else
	SKIP_SBIN=1
fi

# Unset all Termux LD_* enviroment variables to prevent `su` dlopen()ing wrong libs.
unset LD_LIBRARY_PATH
unset LD_PRELOAD

### ----- MAGISKSU
# shellcheck disable=SC2117
if [[ -z "$SKIP_SBIN" && "$(/sbin/su -v)" == *"MAGISKSU" ]]; then
	# We are on Magisk su
	su_cmdline=("/sbin/su")
	[[ -z "$SWITCH_USER" ]] || su_cmdline+=("$SWITCH_USER")
	su_cmdline+=("-c" "PATH=$BB_MAGISK env -i $ENV_BUILT $STARTUP_SCRIPT")
	exec "${su_cmdline[@]}"
	##### ----- END MAGISKSU
else
	##### ----- OTHERS SU
	for SU_BINARY in "${SU_BINARY_SEARCH[@]}"; do
		if [[ -x "$SU_BINARY" ]]; then
			# Let's use the system toybox/toolbox for now
			su_cmdline=("/sbin/su")
			[[ -z "$SWITCH_USER" ]] || su_cmdline+=("$SWITCH_USER")
			su_cmdline+=("-c" "PATH=$ANDROIDSYSTEM_PATHS env -i $ENV_BUILT $STARTUP_SCRIPT")
			exec "${su_cmdline[@]}"

		fi
	done
fi
##### ----- END OTHERS SU

# We didnt find any su binary
set +x
printf -- "No superuser binary detected. \n"
printf -- "Are you rooted? \n"

if [[ -n "$_TSU_DEBUG" ]]; then
	echo "-------------------------------------"
	echo "tsu ran in debug mode."
	echo "Full log can be found in tsu_debug.log"
	echo "Report any issues to: https://github.com/cswl/tsu "
fi

exit 1
