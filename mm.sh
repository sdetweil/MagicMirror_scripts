#!/bin/bash
cd ~/MagicMirror
'''
if [ $(ps -ef | grep -v grep | grep -e wayfire -e labwc | wc -l) -ne 0 ]; then 
   WAYLAND_DISPLAY=wayland-1   
   npm run start:wayland
else
   DISPLAY=:0 npm start
fi 
'''
DISPLAY=:0 npm start  
