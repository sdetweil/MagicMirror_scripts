#!/bin/bash
sudo apt-get purge nodejs &&\
sudo rm -r /etc/apt/sources.list.d/nodesource.list &&\
sudo rm -r /etc/apt/keyrings/nodesource.gpg