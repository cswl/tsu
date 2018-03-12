## tsu

[![Build Status](https://travis-ci.org/cswl/tsu.png?branch=master)](https://travis-ci.org/cswl/tsu)

A su wrapper for Termux.

tsu (like tsu as in tsunami, you know ) is an su wrapper for the
terminal emulator and packages for Android, Termux.

Unlike my quick,throwout script I wrote [a while back](https://gist.github.com/cswl/cd13971e644dc5ced7b2),
tsu will focus only on dropping into root shell from termux.  
It seems running commands as root, would require something on a level of sudo.
Which turns out be too much for a bash script.

### Background
Termux relies on LD_LIBRARY_PATH enviroment variables to find it's libraries.
For security reasons some environent variables seem to be reset by su, unless
an --preserve-environent flag is passed.  
tsu handles this for you and also launches your preferred shell.  
su by default will use sh or mksh, depending upon how it is on your device.


### Installation
`tsu` is now available as a termux package. Install it with.

```
pkg install tsu
```


### Usage
```
tsu - A su wrapper for Termux.

Usage:

tsu [-s|-p|-e]
tsu by default will try to launch an interactive shell.
The interactive shell is searched as follows:
	User's chosen shell in $HOME/.termux/shell
	The bash shell if installed
	The default installed busybox sh shell from termux
	If you need to start another shell. See the -s option

Options Explanation.

-s [</path/to/shell>]
   Use an alternate specified shell. `//usr` is expanded to $PREFIX.
   For convience, if the path starts by `//usr` it will be expaned to Termux's $PREFIX,
   which is the usr directory of Termux.
   So -s '//usr/bin/bash' will be, "/data/data/com.termux/files/usr/bin/bash"

-p
	Prepend /system/bin and /system/xbin to PATH.
	So that binaries in /system/bin and /system/xbin/bash will be
	prefrred over the ones provided by termux.
	Sometimes you may want to run the system binaries as root from Termux.
	Or for cases, where some scripts might expect behavior from the
	default Android toolbox, busybox.

-e
	Setup up some enviroment variables as when in Termux.
	This adds some default Termux variables, when you wanna run Termux commands from other places like
	adb shell.
	Currently it sets HOME to Termux's home, and adds Termux's bin to PATH, following the -p option.

```


### Contributing
Know something you wanna add/improve, you're more than welcome to open a issue or create a pull request.  
The README was written in a hurry, so some help here too.

### License
Licensed under the ISC license. See [LICENSE](https://github.com/cswl/tsu/blob/master/LICENSE.md).
