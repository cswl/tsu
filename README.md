### tsu

Gain a root shell on Termux while being able to run Termux commands as root.  

Or run one off commands with well known `sudo` from normal linux distros.

```shell,tsu
tsu A su interface wrapper for Termux

    Usage:
        tsu
        tsu [ -s SHELL ]  [-p|-a] [USER]
        tsu --dbg [ -s SHELL ] [-p|-a] [-E] [USER]
        tsu -h | --help | --version

    Options:
    --dbg        Enable debug output
    -s <shell>   Use an alternate specified shell.
    -p           Prepend system binaries to PATH
    -a           Append system binaries to PATH
    -h --help    Show this screen.

    This package also provides a minimal sudo which is enough to run most programs as root

        sudo command

    https://github.com/cswl/tsu 
```

### Building
A simple python script is used to make the final shell script as to avoid duplication in documentation.

Run it by using:
`python3 extract_usage.py`

### License

Licensed under the ISC license. See [LICENSE](https://github.com/cswl/tsu/blob/v8/LICENSE.md).

Portions of the `extract_usage.py` is extraced from [excode](https://github.com/nschloe/excode)   which is under the [MIT LICENSE](https://github.com/cswl/tsu/blob/v8/LICENSE_MIT)
