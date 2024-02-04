#/bin/bash
logfile=~/screensaver.log
mac=$(uname -s)

	if [ $mac == 'Darwin' ]; then
	  # get the current setting
	  setting=$(defaults -currentHost read com.apple.screensaver idleTime)
		# if its on
		if [ $setting != 0 ] ; then
		  # turn it off
			echo disable screensaver via mac profile >> $logfile
			defaults -currentHost write com.apple.screensaver idleTime 0
		else
			echo mac profile screen saver already disabled >> $logfile
		fi
	else
	  # find out if some screen saver running

		# get just the running processes and args
		# just want the program name
		# find the 1st with 'saver' in it (should only be one)
		# if the process name is a path, parse it and get the last field ( the actual pgm name)

		screen_saver_running=$(ps -A -o args | awk '{print $1}' | grep -m1 [s]aver | awk -F\/ '{print $NF}');

		# if we found something
		if [ "$screen_saver_running." != "." ]; then
		  # some screensaver running
			case "$screen_saver_running" in
			 mate-screensaver) echo 'mate screen saver' >>$logfile
						gsettings set org.mate.screensaver lock-enabled false	 2>/dev/null
						gsettings set org.mate.screensaver idle-activation-enabled false	 2>/dev/null
						gsettings set org.mate.screensaver lock_delay 0	 2>/dev/null
				 echo " $screen_saver_running disabled" >> $logfile
				 DISPLAY=:0  mate-screensaver  >/dev/null 2>&1 &
			   ;;
			 gnome-screensaver) echo 'gnome screen saver' >>$logfile
			   gnome_screensaver-command -d >/dev/null 2>&1
				 echo " $screen_saver_running disabled" >> $logfile
			   ;;
			 xscreensaver) echo 'xscreensaver running' | tee -a $logfile
			   xsetting=$(grep -m1 'mode:' ~/.xscreensaver )
				 if [ $(echo $xsetting | awk '{print $2}') != 'off' ]; then
					 sed -i "s/$xsetting/mode: off/" "$HOME/.xscreensaver"
					 echo " xscreensaver set to off" >> $logfile
				 else
				   echo " xscreensaver already disabled" >> $logfile
				 fi
			   ;;
			 gsd-screensaver | gsd-screensaver-proxy)
					setting=$(gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null)
					setting1=$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)
					if [ "$setting. $setting1." != '. .' ]; then
						if [ "$setting $setting1" != 'false uint32 0' ]; then
							echo disable screensaver via gsettings was $setting and $setting1>> $logfile
							gsettings set org.gnome.desktop.screensaver lock-enabled false
							gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
							gsettings set org.gnome.desktop.session idle-delay 0
						else
							echo gsettings screen saver already disabled >> $logfile
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
				if [ "$setting $setting1" != 'false uint32 0' ]; then
					echo disable screensaver via gsettings was $setting and $setting1>> $logfile
					gsettings set org.gnome.desktop.screensaver lock-enabled false
					gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
					gsettings set org.gnome.desktop.session idle-delay 0
				else
					echo gsettings screen saver already disabled >> $logfile
				fi
			fi
		fi
		if [ -e "/etc/lightdm/lightdm.conf" ]; then
		  # if screen saver NOT already disabled?
		  if [ $(grep 'xserver-command=X -s 0 -dpms' /etc/lightdm/lightdm.conf | wc -l) != 0 ]; then
		    echo screensaver via lightdm already disabled but need to be updated >> $logfile
		    sudo sed -i -r "s/^(xserver-command.*)$/xserver-command=X -s 0/" /etc/lightdm/lightdm.conf
		  else
		    if [ $(grep 'xserver-command=X -s 0' /etc/lightdm/lightdm.conf | wc -l) == 0 ]; then
		      echo disable screensaver via lightdm.conf >> $logfile
		      sudo sed -i '/^\[Seat:/a xserver-command=X -s 0' /etc/lightdm/lightdm.conf
		    else
		      echo screensaver via lightdm already disabled >> $logfile
		    fi
		  fi
		fi
		if [ -d "/etc/xdg/lxsession/LXDE-pi" ]; then
		  currently_set_old=$(grep -m1 '\-dpms' /etc/xdg/lxsession/LXDE-pi/autostart)
		  currently_set=$(grep -m1 '\xset s off' /etc/xdg/lxsession/LXDE-pi/autostart)
		  if [ "$currently_set_old." != "." ]; then
		    echo lxsession screen saver already disabled but need to updated >> $logfile
		    sudo sed -i "/^@xset -dpms/d" /etc/xdg/lxsession/LXDE-pi/autostart
		    export DISPLAY=:0; xset s noblank;xset s off
		  else
		    if [ "$currently_set." == "." ]; then
		      echo disable screensaver via lxsession >> $logfile
				# turn it off for the future
				sudo su -c "echo -e '@xset s noblank\n@xset s off\n@xset -dpms' >> /etc/xdg/lxsession/LXDE-pi/autostart"
				# turn it off now
				export DISPLAY=:0; xset s noblank;xset s off;xset -dpms
		    else
		      echo lxsession screen saver already disabled >> $logfile
		    fi
		  fi
		fi
		if [ -e "$HOME/.config/wayfire.ini" ]; then
			#  current_set=$(grep -m1 "dpms_timeout" $HOME/.config/wayfire.ini | awk '{print $3}')
			#  if [ "$current_set" != 0 ]; then
			#    echo disable screensaver via wayfire.ini >> $logfile
			#    sed -i -r "s/^(dpms_timeout.*)$/dpms_timeout = 0/" $HOME/.config/wayfire.ini
			#  else
			#    echo wayland screen saver already disabled >> $logfile
			#  fi
			echo "Found: wayfire.ini" >> $logfile
			INI_PATH=$HOME/.config
			WAYFIRE_CONFIG=$INI_PATH/wayfire.ini
			IDLE='\[idle\]'
			DPMS=dpms_timeout
			IDLE_LINE=0
			DPMS_LINE=0
			DPMS_SETTING=0  # 0 = off, 1 = on
			change=0
			# get the line count
			lc=$(wc -l <$WAYFIRE_CONFIG)
			# find the idle line and its line number
			IDLE_STRING=$(grep -n $IDLE $WAYFIRE_CONFIG)
			# find the dpms line and its line number
			DPMS_STRING=$(grep -n $DPMS $WAYFIRE_CONFIG)
			# if we found the idle line
			if [ "$IDLE_STRING." != "." ]; then
				#  extract line number
				IDLE_LINE=$(echo $IDLE_STRING | awk -F: '{print $1}')
			fi
			# if we found the dpms line
			if [ "$DPMS_STRING." != "." ]; then
				# extract line number
				DPMS_LINE=$(echo $DPMS_STRING | awk -F: '{print $1}')
				# extract its value  (after = sign)
				DPMS_VALUE=$(echo $DPMS_STRING | awk -F= '{print $2}')
				# set the value to write out
				DPMS_OUT=$DPMS_SETTING
			fi

			if [ $IDLE_LINE -ne 0 -a $DPMS_LINE -ne 0 -a $DPMS_LINE -gt $IDLE_LINE ]; then
				# both found
				# if we found the DPMS_VALUE != 0
				if [ $DPMS_VALUE -ne 0 ]; then
					sed -i "s/$DPMS=.*/$DPMS=$DPMS_OUT/g" $WAYFIRE_CONFIG
					((change++))
				else
					echo "wayfire screen saver already disabled" | tee -a $logfile
				fi
			# if both NOT found
			elif [ $IDLE_LINE -eq 0 -a $DPMS_LINE -eq 0 ]; then
				# add the two lines
				echo $IDLE | tr -d '\\' >> $WAYFIRE_CONFIG
				echo $DPMS=$DPMS_SETTING >> $WAYFIRE_CONFIG
				((change++))
			# if we found the idle line, (but not dpms)
			elif [ $IDLE_LINE -ne 0 ]; then
				# IDLE was found
				if [ $DPMS_LINE -eq 0 ]; then
					# DPMS  not found
					# insert DPMS after idle
					sed -i /$IDLE/a\ $DPMS=$DPMS_SETTING $WAYFIRE_CONFIG
					((change++))
				fi
			else
				# DPMS IS found , idle not found?  weird
				# insert idle before DPMS?? is this a problem?
				# lets add both to the end, removing the old one first
				# remove the dpms line, wherever it is
				grep -v $DPMS $WAYFIRE_CONFIG>$INI_PATH/wayfire.ini.tmp
				# add the idle  line
				echo $IDLE | tr -d '\\' >>$INI_PATH/wayfire.ini.tmp
				#add the dpms line
				echo $DPMS=$DPMS_SETTING >>$INI_PATH/wayfire.ini.tmp
				# copy the current wayfire.ini to save place
				cp $WAYFIRE_CONFIG $WAYFIRE_CONFIG.old
				# coppy the work ini to the correct file
				cp $INI_PATH/wayfire.ini.tmp $WAYFIRE_CONFIG
				# remove the work file
				rm  $INI_PATH/wayfire.ini.tmp
				((change++))
			fi
			if [ $change -ne 0 ]; then 
				echo disable screensaver via $WAYFIRE_CONFIG >> $logfile
			fi
		fi
	fi
