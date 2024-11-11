# MagicMirror² installation and setup scripts


These scripts can be used to automate installation and release upgrades.

## Install MagicMirror²

`raspberry.sh` is the installation script, upgraded from the core package.

To execute the install script, copy/paste this line into the terminal window on your device (I can't say PI, cause it works in a lot of other places too).

```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/raspberry.sh)"
```

There is a log file, ~/install.log, created so we can be able to diagnose any problems.

## Upgrade to next MagicMirror version from an existing installation

A new MagicMirror version is released once every 90 days (Jan 1, Apr 1, July 1, Oct 1).

`upgrade-script.sh` will do the `git pull` and `npm install`, and refresh npm setup for any modules that might need it.
The script should handle all the work…

and give you a trial run of all that, only applying changes if you request them.

Give it a try!

This works on Mac as well, copy/paste the following line into the terminal window on your device:

```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/upgrade-script.sh)"
```
No changes are made to the local repo or the working copy.

If you WANT to actually apply the changes, copy/paste this line into the terminal window on your device:

```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/upgrade-script.sh)" apply
```
There is a log file (`upgrade.log`)  in the `MagicMirror/installers` folder.

## Additional scripts that may be useful

The install has two sections of additional support.

I have provided those separately here too, in case you need to run one separately, or changed your mind after install.

### Turn off screen saver 

`screensaveroff.sh`, copy/paste this line into the terminal window on your device:

```bash
bash -c "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/screensaveroff.sh)"
```
### Add using pm2 to autostart MagicMirror at bootup

`fixuppm2.sh`, copy/paste this line into the terminal window on your device:

```bash
bash -c "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror_scripts/master/fixuppm2.sh)"
```

## Switch to the Midori or firefox or surf browser
When using the Browser over server mode (instead of the built in electron browser) as shown by package.json using "start":"./run-start.sh", you MAY be able to change which Browser to use, see below

Especially low powered devices like the Pi Zero W might struggle running MagicMirror with the Chromium browser. A simpler browser like Midori, Firefox, or Surf might be a good alternative in this case. To switch to using the Midori  browser, change the `MagicMirror/installers/mm.sh` file to include the `external_browser` variable like this:

```bash
cd ~/MagicMirror
export external_browser=midori
DISPLAY=:0 npm start
```

To switch to using the Firefox browser change the `MagicMirror/installers/mm.sh` file to include the `external_browser` like this:


```bash
cd ~/MagicMirror
export external_browser=firefox
DISPLAY=:0 npm start
```

To switch to using the Surf browser change the `MagicMirror/installers/mm.sh` file to include the `external_browser` like this:


```bash
cd ~/MagicMirror
export external_browser=surf
DISPLAY=:0 npm start
```
