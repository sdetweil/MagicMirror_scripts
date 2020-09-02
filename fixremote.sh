#!/bin/bash
git remote rm origin
git remote add  origin https://github.com/MichMich/MagicMirror.git
git fetch
git branch --set-upstream-to=origin/develop develop
git pull