#!/bin/bash
cd ~/MagicMirror

if [ $(ps -ef | grep -v grep | grep -i -e xway -e labwc | wc -l) -ne 0 ]; then 
   # if WAYLAND_DISPLAYis set, use it, else set to -0
   export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:=wayland-0}
   npm run start:wayland
else
   DISPLAY=:0 npm start
fi 

#DISPLAY=:0 npm start  
