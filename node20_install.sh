#!/bin/bash
arch=
t=$(uname -m)
if [ $t == "aarch64" ]; then
	arch="arch=arm64"
fi

sudo apt-get purge nodejs -y &&\
sudo rm -r /etc/apt/sources.list.d/nodesource.list &&\
sudo rm -r /etc/apt/keyrings/nodesource.gpg

NODE_MAJOR=20
OS=$(lsb_release -a 2>/dev/null | grep name: | awk '{print $2}')
if [ $OS == "buster" ]; then
	NODE_MAJOR=18
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "deb [$arch Pin-Priority=600 signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt-get update
sudo apt-get install nodejs -y
