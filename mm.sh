#!/bin/bash
cd ~/MagicMirror

if [ $(ps -ef | grep -v grep | grep -i -e xway -e labwc | wc -l) -ne 0 ]; then 
   npm run start:wayland
else
   DISPLAY=:0 npm start
fi 

#DISPLAY=:0 npm start  
