#!/bin/bash
# JB-Scripts Command Line Tool
JKITVERSION=1.0.0
JKITBD=2017.04.24

jcltmanual() {
    pager <<jkmnl
<JB-Scripts Command Line Tool manual>

Notes:
Keep in mind that JB-Scripts Command Line Tool is still in very early development and bugs are expected.
JBS-CLT will be installed as jclt in /usr/bin.

Navigation:
Arrows keys: Navigate/Scroll through manual.
q: Exit manual.

Argument usage:
$ $(basename $0) <argument>

<Argument list>

Script core:
version | Display version.
install | Install JBS-CLT to /usr/bin.
uninstall | Uninstall JBS-CLT from /usr/bin.
help | View this manual.

Tools:
sysupd | Perform a system update.

Edition specific:
a2rl | Reload Apache2 server.
a2rs | Restart Apache2 server.
fel | Follow Apache2 error.log.
jkmnl
}

case $1 in
    # General
    install)
    if [ ! -f /usr/bin/jclt ]; then
        echo "Installing jclt to /usr/bin..."
    else
        echo "Updating JBS-CLT over existing installation..."
    fi
    sudo cp $(basename $0) /usr/bin/jclt
    echo "Execute 'jclt help' for arguments."
    exit
    ;;
    uninstall)
    if [ -f /usr/bin/jclt ]; then
        echo "Uninstalling jclt from /usr/bin..."
    else
        echo "JBS-CLT is not installed."
        exit
    fi
    sudo rm /usr/bin/jclt
    exit
    ;;
    help)
    jcltmanual
    exit
    ;;
    version)
    echo "JBS-CLT version $JKITVERSION | Build date: $JKITBD"
    echo "(C) 2017 JB-Scripts"
    exit
    ;;

    # Tools
    sysupd)
    echo "[JBS-CLT] Starting system update..."
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
    exit
    ;;

    # Edition specific
    a2rl)
    echo "[JBS-CLT] Reloading Apache2..."
    sudo service apache2 reload
    exit
    ;;
    a2rs)
    echo "[JBS-CLT] Restarting Apache2..."
    sudo service apache2 restart
    exit
    ;;
    fel)
    clear
    echo "You are following: error.log"
    echo "[CTRL+C] Stop viewing logfile."
    echo
    sudo tail -f /var/log/apache2/error.log
    exit
    ;;

    # Invalid options
    "")
    echo "JBS-CLT version $JKITVERSION"
    echo "Please execute 'jclt help' for arguments."
    exit
    ;;
    *)
    echo "$1 is not a valid argument."
    echo "Please view 'jclt help' for available arguments."
    exit
esac
exit
