# !/bin/bash
# chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt-get update
sudo apt-get install google-chrome-stable 
# pip3
sudo apt-get install python3-pip
# git 
sudo apt-get install git
# virtualenv
pip3 install virtualenv
# jupyter 
pip3 install jupyter
# visual studio code
sudo apt-get install curl
sudo sh -c 'curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg'
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code
# 원격
sudo apt-get install remmina 
# anydesk
#wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
#echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
#sudo apt update
#sudo apt install anydesk
