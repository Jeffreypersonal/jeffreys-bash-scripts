#!/bin/bash
# Web server manager script
VERSION=1.0.1
BUILD=2017.04.25

# Preferences
RELOADAW=true                           # Reload Apache2 service automatically after a certain change is done.
ENABLEBACKUP=true                       # Enable automatic backup when modifying 000-default/apache2 config file.

# Functions
function modfile {
UNEDITEDFILE=`stat -c %Y "$FILE"`
sudo nano $FILE

if [[ `stat -c %Y "$FILE"` -gt $UNEDITEDFILE ]] ; then
  echo "Configuration file modified successfully."
  echo
  reloadserver
else
  echo "No changes are made."
fi
}

function changelogview {
clear
# Update types: Core functionality, User interface, Bug fixes.
pager <<Chnglg
Use the arrow keys to navigate and 'q' button to exit the changelog.

[2017.04.25: Version 1.0.1]
- Updated title at authentication welcome screen.

[2017.04.24: Version 1.0.0]
- Initial release
Chnglg
mainmenu
}

function nonexisting {
    dialog --title "Notice" --keep-tite --msgbox "This feature is planned in a future update and is not currently implemented." 7 60
    mainmenu
}

function finishrespond {
	echo "Managing file: $FILE"
	echo
	echo "[SELECT OPTION]"
    echo "Select an option by typing the letter inside the bracket:"
    echo
	echo "[E] Re-edit file, reload & return to this menu."
	echo "[R] Restore old file, reload & return to main menu."
	echo "[T] Restore old file, reload & re-edit."
	echo "[X] Exit web server manager."
	echo "Anything else: Return to main menu."
	echo
	read -r -p "Select option: " -n1 response
	case $response in
	    [eE]|[eE])
		clear
	    autobackup
		echo
		modfile
		echo
		finishrespond
		exit $?
	    ;;
	    [rR]|[rR])
		echo
		restorefile
		echo
		read -rsp $'Press any key to return to main menu...' -n1 key
		mainmenu
		exit $?
		;;
	    [tT]|[tT])
		clear
		restorefile
		echo
		autobackup
		echo
		modfile
		echo
		finishrespond
		exit $?
		;;
	    [xX]|[xX])
		clear
		exit $?
		;;
	    *)
	    mainmenu
		exit $?
	    ;;
	esac
}

function viewlogsearch {
    cmd=(dialog --title "Filtering [$LOGFILEAP]" --keep-tite --inputbox "Enter a filter below. (Leave empty to view full logfile):" 9 40)
    maincmd=$("${cmd[@]}" 2>&1 >/dev/tty)
    if [ $? -eq "1" ]; then
        finishlogview
        exit $?
    fi
    if [ -z "$maincmd" ]; then
        clear && clear && clear
        sudo cat /var/log/apache2/$LOGFILEAP
        echo
        echo "You are viewing: $LOGFILEAP"
    else
        clear && clear && clear
        sudo cat /var/log/apache2/$LOGFILEAP | grep "$maincmd"
        echo
        echo "You are viewing: $LOGFILEAP"
        echo "Filter: $maincmd"
    fi
    echo
    read -rsp $'Press any key to if you are finished...' -n1 key
    finishlogview
    exit $?
}

function aboutdialog {
    dialog --title "About" --keep-tite --msgbox "Version: $VERSION\nBuild date: $BUILD\n(C) 2017 JB-Scripts" 8 45
    mainmenu
    exit $?
}

function viewlog {
    clear && clear && clear
    sudo cat /var/log/apache2/$LOGFILEAP
    echo
    echo "You are viewing: $LOGFILEAP"
    echo
    read -rsp $'Press any key to if you are finished...' -n1 key
    finishlogview
    exit $?
}

function viewlogfollow {
    clear && clear && clear
    echo "You are following: $LOGFILEAP"
    echo "[CTRL+C] Stop viewing logfile."
    echo
    sudo tail -f /var/log/apache2/$LOGFILEAP
    echo
    read -rsp $'Press any key if you are finished...' -n1 key
    finishlogview
    exit $?
}

function finishlogview {
    clear
    cmd=(dialog --title "Logfile viewer" --keep-tite --menu "Use the arrow keys or type the letter coloured in red to select an option:" 22 56 16)
	options=(r "[error.log] View with filtering"
    e "[error.log] View full log"
    u "[error.log] View & follow"
    y "[access.log] View with filtering"
    a "[access.log] View full log"
    o "[access.log] View & follow"
    f "Return to main menu.")
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
for choice in $choices
do
    case $choice in
	    [rR]|[rR])
        LOGFILEAP=error.log
		viewlogsearch
		exit $?
	    ;;
	    [eE]|[eE])
        LOGFILEAP=error.log
        viewlog
        exit $?
		;;
	    [yY]|[yY])
        LOGFILEAP=access.log
        viewlogsearch
        exit $?
		;;
	    [xX]|[xX])
        clear
        exit $?
		;;
        [aA]|[aA])
        LOGFILEAP=access.log
        viewlog
        exit $?
        ;;
        [oO]|[oO])
        LOGFILEAP=access.log
        viewlogfollow
        exit $?
        ;;
        [uU]|[uU])
        LOGFILEAP=error.log
        viewlogfollow
        exit $?
        ;;
	    *)
        mainmenu
        exit $?
	    ;;
	esac
done
}


if [ "$RELOADAW" = "true" ]; then
	function reloadserver {
		sudo service apache2 reload
    }
else
    function reloadserver {
	       echo "Server must be reloaded manually to apply changes."
       }
fi

function sudorightsdialog {
  dialog --title "Root authentication" \
	    --yesno "Root authentication failed, do you want to try again?" 7 60
	    response=$?
	    case $response in
   	     0)
		clear
        echo "Please authenticate to continue."
        sudo echo "Root authentication successful."
		if [ $? -ne "0" ]; then
		sudorightsdialog
		else
		mainmenu
		fi
                clear
                exit $?
		;;
   	     1)
		clear
	        exit 1
		;;
   	     255)
		clear
	        exit 1
		;;
	    esac
}

if [ $ENABLEBACKUP = "true" ]; then
function autobackup {
sudo cp $FILE $FILE.bak
if [ $? -ne "0" ]; then
echo "Backup of '$FILE' failed!"
else
echo "Automatic backup: '$FILE' backed up."
fi
}
else
function autobackup {
echo "Backups are disabled, skipping backup procedure."
}
fi

function restorefile {
if [ ! -f $FILE ]; then
echo "There is no file backed up."
else
sudo cp $FILE.bak $FILE
if [ $? -ne "0" ]; then
echo "Restore of '$FILE' failed!"
else
echo "Backup restore: '$FILE' restored."
fi
echo
reloadserver
fi
}




function serverstatus {
clear
cmd=(dialog --title "Apache2 & MySQL server actions" --keep-tite --menu "Select option:" 22 56 16)

options=(1 "Reload Apache2"
    	 2 "Restart Apache2"
         3 "Stop Apache2"
         4 "Start Apache2"
         5 "View Apache2 status"
         6 "Start MySQL"
         7 "Stop MySQL"
         8 "Restart MySQL"
         9 "Reload MySQL"
         10 "View MySQL status"
         11 "Return to main menu")
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
    1)
	sudo service apache2 reload
	echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
	serverstatus
	exit $?
	;;
    2)
    sudo service apache2 restart
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    3)
    sudo service apache2 stop
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    4)
    sudo service apache2 start
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    5)
    sudo service apache2 status
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    6)
    sudo service mysql start
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    7)
    sudo service mysql stop
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    8)
    sudo service mysql restart
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    9)
    sudo service mysql reload
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    10)
    sudo service mysql status
    echo
	read -rsp $'Press any key to return to Apache2 & MySQL manager...' -n1 key
    serverstatus
    exit $?
    ;;
    11)
    mainmenu
    exit $?
    ;;
    esac
done
}




#Main dialog
function mainmenu {
clear
cmd=(dialog --title "JBS Web server manager" --keep-tite --menu "Version: $VERSION [Build date: $BUILD]\nSelect option:" 22 56 16)

options=(1 "Apache2 & MySQL server actions"
    	 2 "Quick action: Follow error.log"
    	 3 "Modify apache2.conf"
    	 4 "Modify 000-default.conf (Sites-Available)"
    	 5 "Restore apache2.conf"
    	 6 "Restore 000-default.conf (Sites-Available)"
    	 7 "View error.log & access.log"
         8 "Feedback - Bug report & feature request"
         9 "About"
         10 "View changelog"
    	 11 "Exit")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
    1)
    serverstatus
	;;
	2)
    LOGFILEAP=error.log
    viewlogfollow
	exit $?
	;;
	3)
	FILE="/etc/apache2/apache2.conf"
	autobackup
	echo
	modfile
	echo
	finishrespond
	exit $?
	;;
	4)
	FILE="/etc/apache2/sites-available/000-default.conf"
	autobackup
	echo
	modfile
	echo
	finishrespond
	exit $?
	;;
	5)
	FILE="/etc/apache2/apache2.conf"
	restorefile
	echo
	reloadserver
	echo
	read -rsp $'Press any key to return to main menu...' -n1 key
	mainmenu
	exit $?
	;;
	6)
	FILE="/etc/apache2/sites-available/000-default.conf"
	restorefile
	echo
	reloadserver
	echo
	read -rsp $'Press any key to return to main menu...' -n1 key
	mainmenu
	exit $?
	;;
	7)
    finishlogview
	exit $?
	;;
    8)
    nonexisting
    exit $?
	;;
    9)
    aboutdialog
    exit $?
	;;
    10)
    changelogview
    exit $?
    ;;
	11)
    exit $?
	;;
    esac
done
}
#End of main dialog

#Logic
clear
echo "JBS web server manager version $VERSION"
echo "================================"
echo
echo -e "Hello world!"
echo
echo "Please authenticate to continue."
sudo echo "Authentication OK."
if [ "$?" -ne "0" ]; then
    echo "Authentication failed, make sure you have rights to execute commands with sudo and the correct password is entered."
    exit 1
else
    mainmenu
fi
