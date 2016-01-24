#!/bin/bash

##########################################################################################
#																						 #
# Through iterations of finding versions that worked with one another, the following is  #
# what I was able to come up with.  This script is not tested; it's merely a log of the  #
# commands I used listed as sequentially as I could guess.  This is by no means the most #
# eloquent solution because I have no idea what I'm doing.  I will try to explain why I  #
# differed from the original instructions.  The steps are as follows:                    #
#                                                                                        # 
# 1. Upgrade gcc and g++ - I used gcc-4.9 and g++-4.9 because node-v5.5.0 required		 #
#	compilers >= gcc-4.8 and g++-4.8.  After a quick google search on how to upgrade     #
#	from gcc-4.6 and g++-4.6 in wheezy, the below instructions are what I found.         #
#																						 #
# 2. Install node - Straight forward preconfigured TAR for arm v7 copy/paste to          #
#	/usr/local.																			 #
#																						 #
# 3. Install Python and other packages - Straight forward apt-get for the most part.     #
#																						 #
# 4. Install npm and node packages - Globally installed npm@3.3.12 because sqlite3 was   #
#	having trouble installing on other versions.  I wanted to install node packages      #
#	locally, so I created a directory for the files and added it to the PATH.  The       #
#	packages themselves were simple enough, only sqlite3 was installed directly from the #
#	master.																				 #	
#																						 #
# 5. Install PIBBQMonitor - These instructions are the same except for using sudo on     #
#	some commands.  I changed the the crontab directions so they could be executed from  #
#	the terminal without having to edit the file manually.								 #
#																						 #
##########################################################################################

# 1. Upgrade gcc and g++
# 1a. Update and Upgrade Wheezy

sudo apt-get update -y
sudo apt-get upgrade -y

# 1b. Trick apt-get into looking for files in Jessie source

sudo apt-get install rpl -y
rpl wheezy jessie /etc/apt/sources.list
sudo apt-get update -y
sudo apt-get install gcc-4.9 g++-4.9

# 1c. Undo changes

rpl jessie wheezy /etc/apt/sources.list
sudo apt-get update -y

# 1d. Set symbolic links to new compilers (assumes compilers are in /usr/bin)

cd /usr/bin
sudo rm gcc
sudo rm g++
sudo rm arm-linux-gnueabihf-gcc
sudo rm arm-linux-gnueabihf-g++

sudo ln -s gcc-4.9 gcc
sudo ln -s g++-4.9 g++
sudo ln -s gcc arm-linux-gnueabihf-gcc
sudo ln -s g++ arm-linux-gnueabihf-g++

# 1e. Check links

ls -la | grep gcc
ls -la | grep g++

# 2. Install node

cd ~
sudo wget https://nodejs.org/dist/v5.5.0/node-v5.5.0-linux-armv7l.tar.gz 
tar -xvf node-v5.5.0-linux-armv7l.tar.gz
cd node-v5.5.0-linux-armv7l
sudo cp -R * /usr/local/
cd ~
node -v

sudo apt-get update -y
sudo apt-get upgrade -y

# 3. Install python and other packages

sudo apt-get install python-dev -y
sudo apt-get install python-setuptools -y
sudo easy_install rpi.gpio -y
sudo apt-get install alsa-utils -y
sudo apt-get install mpg321 -y
sudo apt-get install sqlite3 -y
sudo apt-get install libsqlite3-dev -y

# 4. Install npm and node packages
# 4a. Update npm

sudo npm install -g npm@3.3.12
npm -v

# 4b. Change npm's default directory

mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile
source ~/.profile

# 4c. Installing packages

sudo chown -R $USER ~/node_modules
sudo chown -R $USER ~/.npm

npm install node-gyp
npm install node-static
npm install https://github.com/mapbox/node-sqlite3/tarball/master

# 5. Install PIBBQMonitor 
# 5a. Download and copy contents to /home/pi

git clone git://github.com/tilimil/PIBBQMonitor.git 
cp -R ~/PIBBQMonitor/* ~

# 5b. Build sqlite3 table

sqlite3 /home/pi/templog.db "DROP TABLE temps;"
sqlite3 /home/pi/templog.db "CREATE TABLE temps(timestamp timestamp default (strftime('%s', 'now')), sensnum numeric, temp numeric);"

# 5c. Disable any webserver that may already be running on port 80. 

sudo update-rc.d apache2 disable

# 5d. Setup the thermserv node app as a service

sudo cp ~/thermserv_initfile /etc/init.d/thermserv 
sudo chmod 755 /etc/init.d/thermserv 
sudo update-rc.d thermserv defaults

# 5e. Write timed actions to crontab file
(sudo crontab -l 2>/dev/null; echo "*/1 * * * * /home/pi/logger.py") | sudo crontab -
(sudo crontab -l 2>/dev/null; echo "0 * * * * /home/pi/dbcleanup.sh") | sudo crontab -
(sudo crontab -l 2>/dev/null; echo "*/1 * * * * /home/pi/alert.py") | sudo crontab -

# Fin
