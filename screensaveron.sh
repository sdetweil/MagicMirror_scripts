#/bin/bash
logfile=~/screensaver.log
delay=300
mac=$(uname -s)

	if [ $mac == 'Darwin' ]; then
	  # get the current setting	
	  setting=$(defaults -currentHost read com.apple.screensaver idleTime)
		# if its on		
		if [ $setting == 0 ] ; then
		  # turn it off		
			echo disable screensaver via mac profile >> $logfile
			defaults -currentHost write com.apple.screensaver idleTime $delay
		else
			echo mac profile screen saver already enabled >> $logfile
		fi
	else
	  # find out if some screen saver running

		# get just the running processes and args
		# just want the program name
		# find the 1st with 'saver' in it (should only be one)
		# if the process name is a path, parse it and get the last field ( the actual pgm name)

	  screen_saver_running=$(ps -A -o args | awk '{print $1}' | grep -m1 [s]aver | awk -F\/ '{print $NF}');
		# if we found something
		if [ "$screen_saver_running." == "." ]; then
		  # some screensaver running
			case "$screen_saver_running" in
			 mate-screensaver) echo 'mate screen saver' >>$logfile
						gsettings set org.mate.screensaver lock-enabled true	 2>/dev/null
						gsettings set org.mate.screensaver idle-activation-enabled true	 2>/dev/null
						gsettings set org.mate.screensaver lock_delay $delay	 2>/dev/null
				 echo " $screen_saver_running disabled" >> $logfile
				 DISPLAY=:0  mate-screensaver  >/dev/null 2>&1 &
			   ;;
			 gnome-screensaver) echo 'gnome screen saver' >>$logfile
			   gnome_screensaver-command -d >/dev/null 2>&1
				 echo " $screen_saver_running enabled" >> $logfile
			   ;;
			 xscreensaver) echo 'xscreensaver running' | tee -a $logfile
			   xsetting=$(grep -m1 'mode:' ~/.xscreensaver )
				 if [ $(echo $xsetting | awk '{print $2}') != 'on' ]; then
					 sed -i "s/$xsetting/mode: on/" "$HOME/.xscreensaver"
					 echo " xscreensaver set to on" >> $logfile
				 else
				   echo " xscreensaver already enabled" >> $logfile
				 fi
			   ;;
			 gsd-screensaver | gsd-screensaver-proxy)
					setting=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)
					setting1=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)
					if [ "$setting. $setting1." == '. .' ]; then
						if [ "$setting $setting1" == 'false uint32 0' ]; then
							echo disable screensaver via gsettings was $setting and $setting1>> $logfile
							gsettings set org.gnome.desktop.screensaver lock-enabled true
							gsettings set org.gnome.desktop.screensaver idle-activation-enabled true
							gsettings set org.gnome.desktop.session idle-delay $delay
						else
							echo gsettings screen saver already enabled >> $logfile
						fi
					fi
					;;
			 *) echo "some other screensaver $screen_saver_running" found | tee -a $logfile
			    echo "please configure it manually" | tee -a $logfile
			   ;;
		  esac
		fi
		if [ $(which gsettings | wc -l) == 1 ]; then
			setting=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)
			setting1=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)
			if [ "$setting. $setting1." != '. .' ]; then
				if [ "$setting $setting1" == 'false uint32 0' ]; then
					echo enable screensaver via gsettings was $setting and $setting1>> $logfile
					gsettings set org.gnome.desktop.screensaver lock-enabled true
					gsettings set org.gnome.desktop.screensaver idle-activation-enabled true
					gsettings set org.gnome.desktop.session idle-delay $delay
				else
					echo gsettings screen saver already enabled >> $logfile
				fi
			fi
		fi
		if [ -e "/etc/lightdm/lightdm.conf" ]; then
		  # if screen saver NOT already disabled?
			if [ $(grep 'xserver-command=X -s 0 -dpms' /etc/lightdm/lightdm.conf | wc -l) != 0 ]; then
			  echo enable screensaver via lightdm.conf >> $logfile
				sudo sed -i '/^\[Seat:\*\]/a xserver-command=X -s 0 +dpms' /etc/lightdm/lightdm.conf
			else
			  echo screensaver via lightdm already enabled >> $logfile
			fi			
		fi
		if [ -d "/etc/xdg/lxsession/LXDE-pi" ]; then
		  currently_set=$(grep -m1 '\-dpms' /etc/xdg/lxsession/LXDE-pi/autostart)
			if [ "$currently_set." != "." ]; then
				echo enable screensaver via lxsession >> $logfile
				# turn it off for the future
				sudo su -c "echo -e '@xset s noblank\n@xset s off\n@xset -dpms' >> /etc/xdg/lxsession/LXDE-pi/autostart"
				# turn it off now
				export DISPLAY=:0; xset +dpms
			else
			  echo lxsession screen saver already enabled >> $logfile
			fi
		fi
	fi
