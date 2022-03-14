#!/bin/bash

NC='\033[0m' # No Color
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[1;32m' # Boldie Light Green
BLUE='\033[1;34m' # Boldie Light Blue
YELLOW='\033[1;33m' # Boldie Yellow

check_if_installed() {
	PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1 | grep "install ok installed")
	if [ "" == "$PKG_OK" ]; then
		return 2
	fi
	echo -e "${GREEN}- Already installed.${NC}"
	return 1
}

install_packages() {
	apt update
	apt install -y $@
	echo -e "${GREEN}- Installed. ($@)${NC}"
}

# Functions for installing packages

generate_ssh_key() {
	ssh-keygen -t ed25519 -C "marcogonzalo@gmail.com"
	ssh-keygen -p -f ~/.ssh/id_ed25519
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519
	apt install xclip
	xclip -selection clipboard < ~/.ssh/id_ed25519.pub
}

install_utilities() {
	echo -e "${BLUE}Installing utilities:${NC}"
	check_if_installed "filezilla"
        RESPONSE=$?
        if [ "$RESPONSE" -ne "1" ]; then
		install_packages "npm" "terminator"
	fi
}

install_dbeaver() {
	add-apt-repository ppa:serge-rider/dbeaver-ce
	apt update
	apt install dbeaver-ce
}

install_docker() {
	echo -e "${BLUE}Installing Docker CE:${NC}"
	check_if_installed "docker-ce"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		apt remove -y docker docker-engine docker.io containerd runc
 		apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common 
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		install_packages "docker-ce" "docker-ce-cli" "containerd.io"
	fi
	echo -e "${BLUE}Installing Docker Compose:${NC}"
	groupadd docker
	usermod -aG docker $USER
	newgrp docker
	check_if_installed "docker-compose"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		chmod +x /usr/local/bin/docker-compose
		curl -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
		source ~/.bashrc
		echo -e "${GREEN}$(docker-compose --version)"
	fi
}

install_google_chrome() {
	echo -e "${BLUE}Installing Google Chrome:${NC}"
	check_if_installed "google-chrome-stable"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		echo "deb [arch=$(uname -m)] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
		wget https://dl.google.com/linux/linux_signing_key.pub
		apt-key add linux_signing_key.pub
		install_packages "google-chrome-stable"
		rm linux_signing_key.pub
	fi
}

install_git() {
	echo -e "${BLUE}Installing Git:${NC}"
	check_if_installed "git"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		install_packages "git"
	fi
	git config --global user.email "marcogonzalo@gmail.com"
	git config --global user.name "@MarcoGonzalo"
	echo -e "${YELLOW}Let's set your SSH keys!${NC}"
	generate_ssh_key
}

install_sublime_text() {
	echo -e "${BLUE}Installing Sublime Text:${NC}"
	check_if_installed "sublime-text"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
		apt-get install apt-transport-https -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		install_packages "sublime-text"
	fi
}

install_vscode() {
	echo -e "${BLUE}Installing VSCode:${NC}"
	check_if_installed "code"
	RESPONSE=$?
	if [ "$RESPONSE" -ne "1" ]; then
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
		sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
		rm -f packages.microsoft.gpg
	fi
	apt install apt-transport-https
	apt update
	apt install code
}

install_npm() {
	apt install curl 
	curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
	source ./profile
	nvm install node
	npm install -g npm
}

echo -e "<--- ${ORANGE}Starting MGInstaller${NC} --->"
echo -e "${BLUE}Updating and upgrading installed packages${NC}"
apt update
apt upgrade -y
install_utilities
install_npm
install_git
install_docker
install_vscode
install_google_chrome

exit 0
