# MagicMirror_scripts
Magic Mirror installation and setup scripts

these scripts can be used to automate installation of release upgrades.

## raspberry.sh  is the installation script, upgraded from the core package
to execute the install script, cut/paste this line into the terminal window on your device (I can't say PI, cause it works in a lot of other places too)

````bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/raspberry.sh)"
````
there is a log file, MagicMirror/install.log, created so we can be able to diagnose any problems

## upgrade-script.sh will do the git pull and npm install, and refresh npm setup for any modules that might need it
it should handle all the work…
and give you a trial run of all that…

only applying changes if u request them

give it a try
this works on Mac as well, cut/paste this line into the terminal window on your device

````bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/upgrade-script.sh)"
````
no changes are made to the local repo or the working copy

if you WANT to actually apply the changes, cut/paste this line into the terminal window on your device

````bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/upgrade-script.sh)" apply
````
there is a log file (upgrade.log)  in the MagicMirror/installers folder…

## the install has two sections of additional support I have provided those separately too, in case u need to run one separately, or changed your mind after install

### turn off screen saver and setup pm2 to autostart MM on boot..

screensaveroff.sh, cut/paste this line into the terminal window on your device

````bash
bash -c "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/screensaveroff.sh)"
````
fixuppm2.sh, cut/paste this line into the terminal window on your device

````bash
bash -c "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/fixuppm2.sh)"
````
