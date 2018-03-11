#!/bin/bash

red=31
green=32
blue=34

cecho () {
    color=$1
    shift
    echo "\033[${color}m$@\033[m"
}

cecho ${green} "update package list"
sudo apt-get update

cecho ${green} "upgrade package"
sudo apt-get upgrade

cecho ${green} "install rbenv"
sudo apt-get install -i rbenv

cecho ${green} "install ruby-build"
sudo apt-get install -i ruby-build
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

cecho ${green} "install ruby-dev"
sudo apt-get install -i ruby-dev

echo "initialize rbenv"
echo 'export PATH="~/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# install ruby 2.4.0
rbenv install 2.4.0
rbenv versions

# set ruby 2.4.0
rbenv global 2.4.0
rbenv versions
source ~/.bashrc
