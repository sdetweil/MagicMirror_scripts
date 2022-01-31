#!/bin/bash
# only DO npm installs when flag is set to  1
# test when set to 0
true=1
false=0
doinstalls=$false
force=$false
justActive=$true
test_run=$true
stashed=$false
keyFile=package.json
forced_arch=
mfn=MagicMirror
git_active_lock='./.git/index.lock'
lf=$'\n'
git_user_name=
git_user_email=
NODE_TESTED="v16.9.1"
NPM_TESTED="V7.11.2"
NODE_STABLE_BRANCH="${NODE_TESTED:1:2}.x"
known_list="request valid-url"


trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}
function command_exists () { type "$1" &> /dev/null ;}
function verlte() {  [ "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ];}
function verlt() { [ "$1" = "$2" ] && return 1 || verlte $1 $2 ;}
# is this a mac
mac=$(uname -s)
# get the processor architecture
arch=$(uname -m)
if [ $mac == 'Darwin' ]; then
	cmd=greadlink
else
	cmd=readlink
fi
if [ -d ~/$mfn ]; then

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
 # echo the log will be $logfile
	echo  >>$logfile
	date +"Upgrade started - %a %b %e %H:%M:%S %Z %Y" >>$logfile
	echo system is $(uname -a) >> $logfile
	OS=.
	if [ $mac == 'Darwin' ]; then
		echo the os is $(system_profiler SPSoftwareDataType | grep -i "system version" | awk -F: '{ print $2 }') >> $logfile
	else
		echo the os is $(lsb_release -a) >> $logfile
		OS=$(lsb_release -a 2>/dev/null | grep name: | awk '{print $2}')
	fi

	# because of how its executed from the web, p0 gets overlayed with parm
	# check to see if a parm was passed .. easy apply without  editing
	p0=$0
	# if not 'bash', and some parm specified
	if [ $0 != 'bash' -a "$1." != "." ]; then
		# then executed locally
		# get the parm
		p0=$1
	fi
	# lowercase it.. watch out, mac stuff doesn't work  with tr, etc
	p0=$(echo $p0  | cut -c 1-5 |  awk '{print tolower($0)}' )
	if [ $p0 == 'apply' ]; then
		echo user requested to apply changes >>$logfile
		doinstalls=$true
		test_run=$false
	elif [ $p0 == 'force' ]; then
		echo user requested to force apply changes >>$logfile
		doinstalls=$true
		force=$true
		test_run=$false
	fi

	if [ $test_run == $true ]; then
		echo
		echo doing test run = true, NO updates will be applied! | tee -a $logfile
		echo
	else
		echo doing test run = false | tee -a $logfile
	fi

	echo update log will be in $logfile

	# Check if we need to install or upgrade Node.js.
	echo -e "\e[96mCheck current Node installation ...\e[0m" | tee -a $logfile
	NODE_INSTALL=false
	if command_exists node; then
		echo -e "\e[0mNode currently installed. Checking version number." | tee -a $logfile
		NODE_CURRENT=$(node -v)
		if [ "$NODE_CURRENT." == "." ]; then
		   NODE_CURRENT="V1.0.0"
			 echo forcing low Node version  >> $logfile
		fi
		echo -e "\e[0mMinimum Node version: \e[1m$NODE_TESTED\e[0m" | tee -a $logfile
		echo -e "\e[0mInstalled Node version: \e[1m$NODE_CURRENT\e[0m" | tee -a $logfile
		if verlt $NODE_CURRENT $NODE_TESTED; then
			echo -e "\e[96mNode should be upgraded.\e[0m" | tee -a $logfile
			NODE_INSTALL=true

			# Check if a node process is currenlty running.
			# If so abort installation.
			if pidof "node" > /dev/null; then
				echo -e "\e[91mA Node process is currently running. Can't upgrade." | tee -a $logfile
				echo "Please quit all Node processes and restart the installer." | tee -a $logfile
				echo $(ps -ef | grep node | grep -v color) | tee -a $logfile
				exit;
			fi

		else
			echo -e "\e[92mNo Node.js upgrade necessary.\e[0m" | tee -a $logfile
		fi

	else
		echo -e "\e[93mNode.js is not installed.\e[0m" | tee -a $logfile
		NODE_INSTALL=true
	fi
	# Install or upgrade node if necessary.
	if $NODE_INSTALL; then
		if [ $doinstalls == $true ]; then
			echo -e "\e[96mInstalling Node.js ...\e[90m" | tee -a $logfile
            sudo apt-get --allow-releaseinfo-change update >>$logfile
			# Fetch the latest version of Node.js from the selected branch
			# The NODE_STABLE_BRANCH variable will need to be manually adjusted when a new branch is released. (e.g. 7.x)
			# Only tested (stable) versions are recommended as newer versions could break MagicMirror.
			if [ $mac == 'Darwin' ]; then
			  brew install node
			else
				# sudo apt-get install --only-upgrade libstdc++6
				node_info=$(curl -sL https://deb.nodesource.com/setup_$NODE_STABLE_BRANCH | sudo -E bash - )
				echo Node release info = $node_info >> $logfile
				if [ "$(echo $node_info | grep "not currently supported")." == "." ]; then
					sudo apt-get install -y nodejs
				else
					echo node $NODE_STABLE_BRANCH version installer not available, doing manually >>$logfile
					# no longer supported install
					sudo apt-get install -y --only-upgrade libstdc++6 >> $logfile
					# have to do it manually
					ARM1=$ARM
	                                if [ $ARM == 'armv6l' ]; then 
        	                                curl -sL https://unofficial-builds.nodejs.org/download/release/${NODE_TESTED}/node-${NODE_TESTED}-linux-armv6l.tar.gz >node_release-${NODE_TESTED}.tar.gz
                	                        node_ver=$NODE_TESTED
                        	        else
						node_vnum=$(echo $NODE_STABLE_BRANCH | awk -F. '{print $1}')
						if [ $ARM == 'x86_64' ]; then
							ARM1= x64
						fi
						# get the highest release number in the stable branch line for this processor architecture
						node_ver=$(curl -sL https://nodejs.org/download/release/index.tab | grep $ARM1 | grep -m 1 v$node_vnum | awk '{print $1}')
						echo "latest release in the $NODE_STABLE_BRANCH family for $ARM is $node_ver" >> $logfile
						# download that file
						curl -sL https://nodejs.org/download/release/v$node_ver/node-v$node_ver-linux-$ARM1.tar.gz >node_release-$node_ver.tar.gz
					fi 
					cd /usr/local
					echo using release tar file = node_release-$node_ver.tar.gz >> $logfile
					sudo tar --strip-components 1 -xzf  $HOME/node_release-$node_ver.tar.gz
					cd - >/dev/null
					rm ./node_release-$node_ver.tar.gz
				fi
				# get the new node version number
				new_ver=$(node -v 2>&1)
				# if there is a failure to get it due to a missing library
				if [ $(echo $new_ver | grep "not found" | wc -l) -ne 0 ]; then
				  #
					sudo apt-get install -y --only-upgrade libstdc++6 >> $logfile
				fi
				echo node version is $(node -v 2>&1 >>$logfile)
			fi
			echo -e "\e[92mNode.js installation Done! version=$(node -v)\e[0m" | tee -a $logfile
		else
			echo -e "\e[92mNode.js upgrade defered, doing test run\e[0m" | tee -a $logfile
		fi
	fi
	# Check if we need to install or upgrade npm.
	echo -e "\e[96mCheck current NPM installation ...\e[0m" | tee -a $logfile
	NPM_INSTALL=false
	if command_exists npm; then
		echo -e "\e[0mNPM currently installed. Checking version number." | tee -a $logfile
		NPM_CURRENT='V'$(npm -v)
		echo -e "\e[0mMinimum npm version: \e[1m$NPM_TESTED\e[0m" | tee -a $logfile
		echo -e "\e[0mInstalled npm version: \e[1m$NPM_CURRENT\e[0m" | tee -a $logfile
		if verlt $NPM_CURRENT $NPM_TESTED; then
			echo -e "\e[96mnpm should be upgraded.\e[0m" | tee -a $logfile
			NPM_INSTALL=true

			# Check if a node process is currently running.
			# If so abort installation.
			if pidof "npm" > /dev/null; then
				echo -e "\e[91mA npm process is currently running. Can't upgrade." | tee -a $logfile
				echo "Please quit all npm processes and restart the installer." | tee -a $logfile
				exit;
			fi
		else
			echo -e "\e[92mNo npm upgrade necessary.\e[0m" | tee -a $logfile
		fi
	else
		echo -e "\e[93mnpm is not installed.\e[0m" | tee -a $logfile
		NPM_INSTALL=true
	fi

	# Install or upgrade node if necessary.
	if $NPM_INSTALL; then
		if [ $doinstalls == $true ]; then
			echo -e "\e[96mInstalling npm ...\e[90m" | tee -a $logfile

			# Fetch the latest version of npm from the selected branch
			# The NODE_STABLE_BRANCH variable will need to be manually adjusted when a new branch is released. (e.g. 7.x)
			# Only tested (stable) versions are recommended as newer versions could break MagicMirror.

			#NODE_STABLE_BRANCH="9.x"
			#curl -sL https://deb.nodesource.com/setup_$NODE_STABLE_BRANCH | sudo -E bash -
		  #
			# if this is a mac, npm was installed with node
			if [ $mac != 'Darwin' ]; then
				sudo apt-get install -y npm >>$logfile
			fi
			# update to the latest.
			echo upgrading npm to latest >> $logfile
			sudo npm i -g npm@${NPM_TESTED:1:1}  >>$logfile
			echo -e "\e[92mnpm installation Done! version=V$(npm -v)\e[0m" | tee -a $logfile
		else
			echo -e "\e[96mnpm upgrade defered, doing test run  ...\e[90m" | tee -a $logfile
		fi
	fi
	# used for parsing the array of module names
	SAVEIFS=$IFS   # Save current IFS
	IFS=$'\n'

	echo | tee -a $logfile
	# if the git lock file exists and git is not running
	if [ -f git_active_lock ]; then
		 # check to see if git is actually running
		 git_running=`ps -ef | grep git | grep -v color | grep -v 'grep git' | wc -l`
		 # if not running
		 if [ git_running == $false ]; then
				# clean up the dangling lock file
				echo erasing abandonded git lock file >> $logfile
				rm git_active_lock >/dev/null 2>&1
		 else
				# git IS running, we can't proceed
				echo it appears another instance of git is running | tee -a $logfile
				# if this is an actual run
				if [ $doinstalls == $true ]; then
					# force it back to test run
					doinstalls = $false
					test_run=$true
					echo forcing test run mode | tee -a $logfile
					echo please resolve git running already and start the update again | tee -a $logfile
				fi
		 fi
	fi

	# change to MagicMirror folder
	cd ~/$mfn

		# save custom.css
		cd css
			if [ -f custom.css ]; then
				echo "saving custom.css" | tee -a $logfile
				cp -p custom.css save_custom.css
			fi
		cd - >/dev/null
		save_alias=$(alias git 2>/dev/null)
        # get the current branch name
		current_branch=$(git branch | grep \* | cut -d ' '  -f2)
		if [ $current_branch != 'master' ]; then
		   echo reverting to master branch from $current_branch, saving changed files | tee -a $logfile
		   changes=$(LC_ALL=C git status | grep modified | awk -F: '{print $2}')
		   if [ "$changes." != "." ]; then
		      	# get the names of the files that are different locally
				# split names into an array
				diffs=($changes) # split to array $diffs

				# if there are different files (array size greater than zero)
				if [ ${#diffs[@]} -gt 0 ]; then
					for file in "${diffs[@]}"
					do
						f="$(trim "$file")"
						if [ $test_run == $false ]; then
							echo "saving file $f as $f.save before switch back to master branch" | tee -a $logfile
							cp $f $f.save
							echo "restoring file $f before switch back to master branch" | tee -a $logfile
							git checkout $f >/dev/null
							:
						else
							echo "would restore file $f before switch back to master branch" | tee -a $logfile
						fi
					done
				fi
		   fi
		   # return to master branch
		   git checkout master >> $logfile
		   r=$?
		   if [ $r -ne 0 ]; then
		   	  cd - >/dev/null
		   	  echo unable to change back to master branch, stopping execution
		   	  date +"Upgrade ended - %a %b %e %H:%M:%S %Z %Y" >>$logfile
		   	  exit
		   fi

		fi
		# get the git remote name
		remote=$(git remote -v 2>/dev/null | grep -i michmich | grep fetch | awk '{print $1}')

		# if remote name set
		if [ "$remote." != "." ]; then

			echo remote name = $remote >>$logfile

		  # get the local and remote package.json versions
			local_version=$(grep -m1 version package.json | awk -F\" '{print $4}' | awk -F-  '{print $1}')
			remote_version=$(curl -sL https://raw.githubusercontent.com/MichMich/MagicMirror/master/package.json | grep -m1 version | awk -F\" '{print $4}')

			# if on 2.9
			if [ $local_version == '2.9.0' ]; then
			  # and the activemodule js file is loaded
				if [ -f installers/dumpactivemodules.js ]; then
				  # erase cause the fetch will pull another, and the merge will fail
					rm installers/dumpactivemodules.js
			    fi
			fi
			# check if current is less than remote, dont downlevel
			$(verlte  "$local_version" "$remote_version")
			r=$?
			if [ "$r" == 0 ]; then
			# only change if they are different
			if [ "$local_version." != "$remote_version." -o $force == $true -o $test_run == $true ]; then
				echo upgrading from version $local_version to $remote_version | tee -a $logfile

				# get the latest upgrade
				echo fetching latest revisions | tee -a $logfile
				LC_ALL=C git fetch $remote &>/dev/null
				rc=$?
				echo git fetch rc=$rc >>$logfile
				if [ $rc -eq 0 ]; then

					# need to get the current branch
					current_branch=$(LC_ALL=C git branch | grep "*" | awk '{print $2}')
					echo current branch = $current_branch >>$logfile
					# find out if package,json has run-start enabled
					fix_runstart=$(grep run-start package.json| wc -l)
					LC_ALL=C git status 2>&1 >>$logfile

					# get the names of the files that are different locally
					diffs=$(LC_ALL=C git status 2>&1 | grep modified | awk -F: '{print $2}')

					# split names into an array
					diffs=($diffs) # split to array $diffs

					# if there are different files (array size greater than zero)
					if [ ${#diffs[@]} -gt 0 ]; then
					  package_lock=0
						echo there are "${#diffs[@]}" local files that are different than the master repo | tee -a $logfile
						echo | tee -a $logfile
						for file in "${diffs[@]}"
						do
							echo "$file" | tee -a $logfile
							if [ $(echo $file | grep  '\-lock.json$' | wc -l) -eq 1 ]; then
								package_lock=$true
							fi
						done
						echo | tee -a $logfile
						if [ $package_lock -eq 1 ]; then
							echo "any *-lock.json files do not need to be saved"
						fi
						read -p "do you want to save these files for later   (Y/n)?" choice
						choice="${choice:=y}"
						echo save/restore files selection = $choice >> $logfile
						set_username=$false
						if [[ $choice =~ ^[Yy]$ ]]; then
						  git_user=$(git config --global --get user.email)
							if [ "$git_user." == "." ]; then
							   set_username=$true
							    git config --global user.name "upgrade_script"
								  git config --global user.email "script@upgrade.com"
							fi
							echo "erasing lock files" >> $logfile
							git reset HEAD package-lock.json >/dev/null
							rm *-lock.json 2>/dev/null
							rm  vendor/*-lock.json 2>/dev/null
							rm  fonts/*-lock.json 2>/dev/null
							git stash >>$logfile
							stashed=$true
						else
							for file in "${diffs[@]}"
							do
								f="$(trim "$file")"
								echo restoring $f from repo >> $logfile
								if [ $test_run == $false ]; then
									git checkout HEAD -- $f | tee -a $logfile
								else
								  echo skipping restore for $f, doing test run | tee -a $logfile
								fi
							done
						fi
					else
						echo no files different from github version >> $logfile
					fi

					# lets test merge, in memory, no changes to working directory or local repo
					test_merge_output=$(LC_ALL=C git merge-tree `git merge-base $current_branch HEAD` HEAD $current_branch | grep "^<<<<<<<\|changed in both")
					echo "test merge result rc='$test_merge_output' , if empty, no conflicts" >> $logfile

					# if there were no conflicts reported
					if [ "$test_merge_output." == "." ]; then

						need_merge=true
						# may have to loop here if untracked files inhibit merge
						# new path will clean up those files
						while [ $need_merge == true ]
						do
							if [ $test_run == $false ]; then
								# go ahead and merge now
								echo "executing merge, apply specified" >> $logfile
								# get the text output of merge
								merge_output=$(LC_ALL=C git merge $remote/$current_branch 2>&1)
								# and its return code
								merge_result=$?
								# make any long line readable
								merge_output=$(echo $merge_output | tr '|' '\n'| sed "s/create/\\${lf}create/g" | sed "s/mode\ change/\\${lf}mode\ change/g")
								echo -e "merge result rc= $merge_result\n $merge_output">> $logfile
							else
							  	echo "skipping merge, only test run" >> $logfile
								merge_output=''
								merge_result=0
							fi
							# watch out for files in new release could be overlayed
							# erase them..
							if [ $merge_result == 1 ]; then
								# and the problem is untracked would overwritten
								if [[ "$merge_output" =~ 'would be overwritten by merge' ]]; then
									echo "found unexpected untracked files present in new release, removing"  >>$logfile
									filelist=$(echo $merge_output | awk -F: '{print $3}' | awk -FP '{print $1}'| tr -d '\t'| tr ' ' '\n')
									files=($filelist)
									for file in "${files[@]}"
									do
										echo "removing file " $file >> $logfile
										rm $file >/dev/null
									done
									# and we will go merge again
								else
								  # some other merge problem
								  need_merge=false
								fi
							else
								# no error, end loop
								need_merge=false
							fi
						done
						# if no merge errors
						if [ $merge_result == 0 ]; then
							# some updates applied
							if [ "$merge_output." != 'Already up to date.' -o $test_run == $true ]; then
								# update any dependencies for base
								if [ $doinstalls == $true ]; then
								  # if this is a pi zero
									echo processor architecture is $arch >> $logfile
									if [ "$arch" == "armv6l" -o $fix_runstart == $true ]; then
									#   # force to look like pi 2
									#	 echo forcing architecture armv7l >>$logfile
									#	 forced_arch='--arch=armv7l'
									  sed '/start/ c \    "start\"\:\"./run-start.sh $1\",' < package.json 	>new_package.json
									  if [ -s new_package.json ]; then
									  	cp new_package.json package.json
									  	rm new_package.json
									  	echo "package.json update for armv6l completed ok" >>$logfile
									  else
									  	echo "package.json update for armv6l failed " >>$logfile
									  fi
									  if [ ! -e run-start.sh ]; then
										curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/run-start.sh >run-start.sh
									    chmod +x run-start.sh
									  fi
								          # on armv6l, new OS's have a bug in browser support
								          # install older chromium if not present
									  v=$(uname -r); v=${v:0:1}
									  if [ "$(which chromium-browser)." == '.' -a ${v:0:1} -ne 4 ]; then 
								                sudo apt install -y chromium-browser >>$logfile
								          fi 
									fi
								    if [ $remote_version == '2.13.0' ]; then
								      # fix downlevel node-ical
								      sed '/node-ical/ c \         "node-ical\"\:\"^0.12.1\",' < package.json >new_package.json
								      rm package.json
								      mv new_package.json package.json
									fi
									echo "updating MagicMirror runtime, please wait" | tee -a $logfile
									npm install $forced_arch --only=prod 2>&1 | tee -a $logfile
									done_update=`date +"completed - %a %b %e %H:%M:%S %Z %Y"`
									echo npm install $done_update on base >> $logfile
									# fixup permissions on sandbox file if it exists
									if [ -f node_modules/electron/dist/chrome-sandbox ]; then
										 echo "fixing sandbox permissions" >>$logfile
										 sudo chown root node_modules/electron/dist/chrome-sandbox 2>/dev/null
										 sudo chmod 4755 node_modules/electron/dist/chrome-sandbox 2>/dev/null
									fi
									# if this is v 2.11 or higher
									newver=$(grep -m1 version package.json | awk -F\" '{print $4}')
									# no compound compare for strings, use not of reverse
									# greater than or equal  means not less than
									if [ ! "$newver" \< "2.11.0" ]; then
									  # if one of the older devices, fix the start script to execute in serveronly mode
									  if [ "$arch" == "armv6l" ]; then
										  # fixup the start script
										  sed '/start/ c \    "start\"\:\"./run-start.sh $1\",' < package.json 	>new_package.json
										  if [ -s new_package.json ]; then
										  	cp new_package.json package.json
										  	rm new_package.json
										  	echo "package.json update for armv6l completed ok" >>$logfile
										  else
										  	echo "package.json update for armv6l failed " >>$logfile
										  fi
										  curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/run-start.sh >run-start.sh
										  chmod +x run-start.sh
										  # add fix to disable chromium update checks for a year from time started
										  sudo touch /etc/chromium-browser/customizations/01-disable-update-check;echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" | sudo tee /etc/chromium-browser/customizations/01-disable-update-check >/dev/null
									  elif [ "$arch" == "x86_64" -a "$OS" == 'buster' ]; then
									  	cd fonts
									  	   sed '/roboto-fontface/ c \    "roboto-fontface": "latest"' < package.json 	>new_package.json
									  	   if [ -s new_package.json ]; then
										  	cp new_package.json package.json
										  	rm new_package.json
										  	echo "package.json update for x86 fontface completed ok" >>$logfile
										  fi
									  	cd -
									  fi
									fi
									if [ $newver == '2.11.0' ]; then
									   npm install eslint
									fi
								fi
								# process updates for modules after base changed
								cd modules

									# lets check for modules with missing requires (libs removed from MM base)
									# this skips any default modules
									echo Checking for modules with removed libraries | tee -a $logfile
									mods=($(find . -maxdepth 2 -type f -name  node_helper.js | awk -F/ '{print $2}'))

									# loop thru all the installed modules
									for  mod in "${mods[@]}"
									do
										# get the require statements from the node helper
										requires=($(grep -e "require(" $mod/node_helper.js | awk -F '[()]' '{print $2}' | tr -d '"' | tr -d "'"))
										# loop thru the requires
										for require in "${requires[@]}"
										do
											# check it against the list of known lib removals
											case " $known_list " in (*" $require "*) :;; (*) false;; esac
											# if found in the list
											if [ $? == 0 ]; then
												# if no package.json, we would have to create one
												cd $mod
												if [ ! -e package.json ]; then
													echo -e ' \n\t ' package.json not found for module $mod | tee -a $logfile
													if [ $doinstalls == $true ]; then
														echo adding package.json for module $mod | tee -a $logfile
														npm init -y >>$logfile
													else
														echo -e ' \n\t\t 'bypass adding package.json for module $mod, doing test run | tee -a $logfile
													fi
												fi
												# if package.json exists, could have been just added
												if [ -e package.json ]; then
													# check for this library in the package.json
													pk=$(grep $require package.json)
													# if not present, need to do install
													if [ "$pk." == "." ]; then
														echo -e ' \n\t 'require for $require in module $mod not found in package.json package.json for module $mod
														if [ $doinstalls == $true ]; then
															echo installing $require for module $mod | tee -a $logfile
															npm install $require --save >>$logfile
														else
															echo -e ' \n\t\t ' bypass installing $require for module $mod , doing test run  | tee -a $logfile
														fi
													fi
												fi
												cd - >/dev/null
											fi
										done
									done

									# now that we may have fixed up module with missing requires
									#  lets see which ones need a new npm install with this version of MM

									if [ $justActive == $true ]; then
										# get the list of ACTIVE modules with  package.json files
										mtype=active
										justloaded=false
											# if we want just the modules listed in config.js now
											# make sure we have the coe locally to get that info
											if [ ! -f ~/$mfn/installers/dumpactivemodules.js ]; then
												echo downloading dumpactivemodules script >> $logfile
												curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/dumpactivemodules.js> ~/$mfn/installers/dumpactivemodules.js
												justloaded=true
											fi
										modules=$(node ../installers/dumpactivemodules.js)
										if [ $justloaded == true ]; then
										   rm ~/$mfn/installers/dumpactivemodules.js
										fi
									else
										# get the list of INSTALLED modules with  package.json files
										mtype=installed
										modules=$(find  -maxdepth 2 -name 'package.json' -printf "%h\n" | cut -d'/' -f2 )
									fi
									modules=($modules) # split to array $modules

									# if the array has entries in it
									if [ ${#modules[@]} -gt  0 ]; then
									  echo >> $logfile
										echo "processing dependency changes for $mtype modules with package.json files" | tee -a $logfile
										echo
										for module in "${modules[@]}"
										do
											echo "processing for module" $module please wait | tee -a $logfile
											echo '----------------------------------' | tee -a $logfile
											# change to that directory
											cd  $module
												# process its dependencies
												if [ $doinstalls == $true ]; then
												     rm -rf node_modules 2>/dev/null
													 rm package-lock.json 2>/dev/null
													 # check to see if the author created a rebuild process
													 do_rebuild=$(grep "\"rebuild\"" package.json | wc -l)
													 # if so, use it
													 if [ $do_rebuild -ne 0 ]; then
													 	npm rebuild 2>&1| tee -a $logfile
													 else
													 	npm install $forced_arch 2>&1| tee -a $logfile
													 fi
												else
													echo skipped processing for $module, doing test run | tee -a $logfile
												fi
											# return to modules folder
											cd - >/dev/null
											echo "processing complete for module" $module | tee -a $logfile
											echo
										done
									else
										echo "no modules found needing npm refresh" | tee -a $logfile
									fi
								# return to Magic Mirror folder
								cd .. >/dev/null
							else
								echo "no changes detected for modules, skipping " | tee -a $logfile
							fi
						else
							echo there were merge errors | tee -a $logfile
							echo $merge_output | tee -a $logfile
							echo you should examine and resolve them 	 | tee -a $logfile
							echo using the command git log --oneline --decorate | tee -a $logfile
							git log --oneline --decorate | tee -a $logfile
						fi
					else
						echo "there are merge conflicts to be resolved, no changes have been applied" | tee -a $logfile
						echo $test_merge_output | tee -a $logfile
					fi
				else
					echo "MagicMirror git fetch failed" | tee -a $logfile
				fi
			else
			  echo "local version $local_version already same as master $remote_version" | tee -a $logfile
			fi
			else
				echo "local version $local_version newer than remote version $remote_version, aborting update" | tee -a $logfile
			fi
		else
		  echo "Unable to determine upstream git repository" | tee -a $logfile
		fi
		# should be in MagicMirror base
		cd css
			# restore  custom.css
			if [ -f save_custom.css ]; then
				echo "restoring custom.css" | tee -a $logfile
				cp -p save_custom.css custom.css
				rm save_custom.css
			fi
		cd - >/dev/null
		#if [ "$lang." != "en_US.UTF-8." ]; then
		   if [ "$save_alias." != "." ]; then
			    echo restoring git alias >>$logfile
			    $save_alias >/dev/null
			 else
			    echo removing git alias >>$logfile
			    #unalias git >/dev/null
			 fi
		#fi
	IFS=$SAVEIFS   # Restore IFS

	if [ $stashed == $true ]; then
		 if [ $test_run == $true ]; then
			 echo test run, restoring files stashed | tee -a $logfile
			 git $git_user_name $git_user_email stash pop  >> $logfile
		 else
			 echo we stashed a set of files that appear changed from the latest repo versions. you should review them | tee -a $logfile
			 git stash show --name-only > installers/stashed_files
			 echo see installers/stashed_files for the list
			 echo
			 echo you can use git checkout "stash@{0}" -- filename to extract one file from the stash
			 echo
			 echo or git stash pop to restore them all
			 echo
			 echo WARNING..
			 echo WARNING.. either will overlay the file just installed by the update
			 echo WARNING..
			 if [ $set_username == $true ]; then
			    git config --global --unset user.name >>/$logfile
					git config --global --unset user.email >>/$logfile
			 fi
		 fi
	fi
	# return to original folder
	cd - >/dev/null
	date +"Upgrade ended - %a %b %e %H:%M:%S %Z %Y" >>$logfile
else
	echo It appears MagicMirror has not been installed on this system
	echo please run the installer, "raspberry.sh" first
fi

