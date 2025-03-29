#!/bin/bash
# This file is still here to keep PM2 working on older installations.
cd ~/MagicMirror
if [ $(ps -ef | grep -v grep | grep -e wayfire -e labwc | wc -l) -ne 0 ]; then 
   WAYLAND_DISPLAY=wayland-1   
   npm run start:wayland
else
   DISPLAY=:0 npm start
fi   
