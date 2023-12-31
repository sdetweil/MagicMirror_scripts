	mfn=MagicMirror
	mac=$(uname -s)
	if [ $mac == 'Darwin' ]; then
    if [ "$(which greadlink)." == "." ]; then
	  brew install coreutils
	fi
		cmd=greadlink
	else
		cmd=readlink
	fi
	# put the log where the script is located
	logdir=$(dirname $($cmd -f "$0"))
	# if the script was execute from the web
	if [[ $logdir != *"MagicMirror/installers"* ]]; then
		# use the MagicMirror/installers folder
		cd ~/$mfn/installers >/dev/null
		logdir=$(pwd)
		cd - >/dev/null
	fi
	logfile=$logdir/upgrade.log
	date +"PM2 Upgrade started - %a %b %e %H:%M:%S %Z %Y" >>$logfile
	if [ "$(which pm2)." != "." ]; then
		pm2_npmjs_version=$(npm view pm2 version)
		pm2_current_version=$(npm list -g --depth=0 | grep -i pm2 | awk -F@ '{print $2}')
		echo pm2 installed, checking version $pm2_current_version vs $pm2_npmjs_version >> $logfile
		if [ 1 -o "${pm2_npmjs_version:0:1}." == "${pm2_current_version:0:1}." -a "$pm2_current_version." != "$pm2_npmjs_version." ]; then
			# if pm2 is managing MagicMirror,, then update
			if [ $(pm2 ls -m | grep "\-\-" | grep -i magicmirror | wc -l) -eq 1 ]; then
				apps_defined=$(pm2 ls -m | grep "\-\-" | wc -l)
				echo pm2 same major version, so updating >> $logfile
				sudo npm install pm2@latest -g 2>&1 >> $logfile
				pm2 update 2>&1 >>$logfile
				rc=$?
				if [ $rc -eq 0 ]; then
					apps_defined_after_update=$(pm2 ls -m | grep "\-\-" | wc -l)
					if [ $apps_defined != $apps_defined_after_update ]; then
						echo rerunning pm2 update , after app count incorrect >> $logfile
						pm2 update 2>&1 >>$logfile
					fi
					echo pm2 update completed >> $logfile
				else
					echo pm2 update failed, rc=$rc | tee -a $logfile
				fi
			else
				echo not managing pm2 >>$logfile
			fi
		else
			echo no pm2 required >>$logfile
		fi
	fi
	date +"PM2 Upgrade ended - %a %b %e %H:%M:%S %Z %Y" >>$logfile
