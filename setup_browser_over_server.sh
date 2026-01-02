#!/bin/bash
# This is an installer script for MagicMirror2. It works well enough
# that it can detect if you have Node installed, run a binary script
# and then download and run MagicMirror2.

if [ $USER == 'root' ]; then
	 echo Please login as a user to execute the MagicMirror installation,  not root
	 exit 1
fi


cd $HOME
# set default log location
logdir=$HOME
mm_folder=MagicMirror
mm_script=$HOME/$mm_folder/installers/mm.sh

mac=$(uname -s)
if [ 0 -eq 1 ]; then
	if [ "$0" == "bash" ]; then
		logdir=.
	else
		if [ $mac == 'Darwin' ]; then
			echo this is a mac >> $logfile
			logdir=$(dirname "$0")
		else
			# put the log where the script is located
				logdir=$(dirname $(readlink -f "$0"))
		fi
	fi

	# if the script was execute from the web
	if [[ $logdir != *"MagicMirror/installers"* ]]; then
		# use the MagicMirror/installers folder, if setup
		if [ -d ~/mm_folder ]; then
			if [ ! -d $HOME/$mm_folder/installers ]; then
				mkdir $HOME/$mm_folder/installers 2>/dev/null
			fi
			cd $HOME/$mm_folder/installers >/dev/null
				logdir=$(pwd)
			cd - >/dev/null
		else
			# use the users home folder if initial install
			logdir=$HOME
		fi
	fi
fi
logfile=$logdir/browser_over_server.log

echo install log being saved to $logfile | tee -a $logfile
if [ ! -d $HOME/MagicMirror ]; then
	echo MagicMirror not installed
	date +"browser over server setup  ending  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
	exit 2
fi
# Determine which Pi is running.
date +"browser over server setup  starting  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
	cd $HOME/MagicMirror
	curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/run-start.sh >run-start.sh
	chmod +x run-start.sh
  	sed '/start\"/ c \    "start\"\:\"./run-start.sh $1\",' < package.json 	>new_package.json
	if [ -e new_package.json ]; then
		cp new_package.json package.json
		rm new_package.json
		echo "package.json update for browser over server, completed ok" >>$logfile
	else
		echo "package.json update for browser over server failed " >>$logfile
	fi

	# if the the pm2 startup script does not exist
	if [ ! -e mm_script ]; then
		echo "mm.sh startup script not present" >> $logfile
		# if we saved the prior
		if [ -e foo.sh ]; then
			echo "use saved copy to restore mm.sh" >> $logfile
			# move it back
			mv foo.sh installers/mm.sh
		else
			# oops didn't save mm.sh or it was lost on prior run
			echo "oops, was no saved copy of mm.sh, restore from repo" >> $logfile
			if [ ! -d installers ]; then
				mkdir installers
			fi
			curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/mm.sh >installers/mm.sh
			chmod +x installers/mm.sh
		fi
	fi

	echo which browser would you like to use
	echo 1 chrome
	echo 2 firefox
	echo 3 midori
	echo 4 surf
	read choice
	choice="${choice:-1}"
	case $choice in 
		1)  echo selected chrome browser
			if [ "$(which chromium-browser)." != "." -o "$(which chrome)." != "." ]; then
				echo chrome already installed | tee -a $logfile
			else
				sudo apt install chromium-browser -y
				echo chrome installed | tee -a $logfile
			fi
			if [ $(grep external_browser $mm_script | wc -l) -eq 0 ]; then
				sed -i '/npm start/i export external_browser=chromium-browser' $mm_script
			else
				#sed -i '/npm start/i export external_browser=chromium-browser' $mm_script
				sed -i "/export external_browser=.*/c\export external_browser=chromium-browser" $mm_script
			fi
			;;
		2)  echo selected firefox browser
			if [ "$(which firefox)." != "." ]; then
				echo firefox already installed | tee -a $logfile
			else
				sudo apt install firefox -y
				echo firefox installed | tee -a $logfile
			fi
			if [ $(grep external_browser $mm_script | wc -l) -eq 0 ]; then
				sed -i '/npm start/i export external_browser=firefox' $mm_script
			else
				#sed -i '/npm start/i export external_browser=chromium-browser' $mm_script
				sed -i "/export external_browser=.*/c\export external_browser=firefox" $mm_script
			fi
			;;
		3)  echo selected midori browser
			if [ "$(which midori)." != "." ]; then
				echo midori already installed | tee -a $logfile
			else
				sudo apt install midori -y
				echo midori installed | tee -a $logfile
			fi
			if [ $(grep external_browser $mm_script | wc -l) -eq 0 ]; then
				sed -i '/npm start/i export external_browser=midori' $mm_script
			else
				#sed -i '/npm start/i export external_browser=chromium-browser' $mm_script
				sed -i "/export external_browser=.*/c\export external_browser=midori" $mm_script
			fi
			;;
		4)  echo selected surf browser
			if [ "$(which surf)." != "." ]; then
				echo surf already installed | tee -a $logfile
			else
				sudo apt install surf -y
				echo surf installed | tee -a $logfile
			fi
			if [ $(grep external_browser $mm_script | wc -l) -eq 0 ]; then
				sed -i '/npm start/i export external_browser=surf' $mm_script
			else
				#sed -i '/npm start/i export external_browser=chromium-browser' $mm_script
				sed -i "/export external_browser=.*/c\export external_browser=surf" $mm_script
			fi
			;;
		*)  echo unknown selection $choice
			;;
	esac

date +"browser over server setup  ending  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
