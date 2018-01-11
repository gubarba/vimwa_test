#!/usr/bin/env bash
RESTORE='\033[0m'
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\e[0;33m'

exit_script=no

find_files(){
	if [[ ! ( -e vimwa_config.sh &&  -e vimwa_keep_running.sh && vimwa_deps_install.sh ) ]]; then
		echo -e "Can't find all necessary files in this folder, please cd into the appliance directory."
		exit
	fi
}

vimwa (){
	menu
}

menu () {
    clear
    echo -e "${YELLOW}VIMWA${RESTORE} VLC's Impossible Mosaic Workaround Appliance"
    echo -e ""
    echo -e "${GREEN}vimwa or menu${RESTORE}      prints ${RED}this menu${RESTORE} (must have sourced the script)"
    echo -e ""
    echo -e "${GREEN}intro${RESTORE}              ${RED}instructions${RESTORE} on how this program works"
    echo -e ""
    echo -e "${GREEN}deps_install${RESTORE}       Installs ${YELLOW}VIMWA${RESTORE}'s dependencies"
    echo -e ""
    echo -e "${GREEN}configure${RESTORE}          Creates the configuration files for ${YELLOW}VIMWA${RESTORE}"
    echo -e ""
    echo -e "${GREEN}overwrite_xinit${RESTORE}    Sets the ${RED}'~/.initrc'${RESTORE} if you wan't to autostart the cameras on boot, for example"
    echo -e ""
    echo -e "${GREEN}kill_viwma${RESTORE}         In case you want to kill the vimwa_keep_running.sh script"
    echo -e ""
}



kill_viwma(){
	if kill `ps aux | grep -v grep | grep vimwa_keep_running.sh | awk '{print $2}'` 2> /dev/null ; then
		echo -e "Found and killed ${YELLOW}vimwa_deps_install.sh${RESTORE} \n "
	else
		echo -e "${YELLOW}vimwa_deps_install.sh${RESTORE} wasn't even running =D \n "
	fi
}

deps_install() {
	clear
		echo -e "This step will try to install the packages dependencies for this appliance to run"
		echo -e "${RED}WARNING${RESTORE}:this uses ${RED}sudo${RESTORE} and will prompt for your password."
	    echo -e "Type \"YES\" if you want to apply it: "
		local confirm
		read confirm		
		if [ $confirm = "YES" ]; then
			sudo apt-get install -y xserver-xorg-video-dummy xserver-xorg-input-void xserver-xorg-core xinit x11-xserver-utils vlc libavcodec-extra xserver-xorg-input-all xterm bc libav-tools --no-install-recommends
		fi
}

configure() {
	if which startx > /dev/null ; then
		if [ -e vimwa.conf ]; then
			clear
			echo -e "This step will overwrite the current configuration"
			echo -e "${RED}WARNING${RESTORE}: make sure you got a file with one video resource per line."
		    echo -e "Type \"YES\" if you want to proceed: "
			local confirm
			read confirm
			if [ $confirm = "YES" ]; then
				startx `which xterm` -maximized -e 'bash ./vimwa_config.sh'
			fi
		else
			printf "xrandr_command=\nresources=\n" > vimwa.conf
			startx `which xterm` -maximized -e 'bash ./vimwa_config.sh'
		fi
	else
		printf "\n Sorry, couldn't find the startx command, did you run the install_app command?"
	fi
}

overwrite_xinit(){
	clear
	echo -e "This step will overwrite this user's ~/.xinitrc with the call no keep_running.sh so Xorg start the cameras when you run startx"
	echo -e "${RED}WARNING${RESTORE}: only use this function if you know what you're doing and want to use this as an appliance."
    echo -e "Type \"YES\" if you want to apply it: "
	local confirm
	read confirm
	if [ $confirm = "YES" ]; then
		# xset s off and xset -dpms  -> disable screen blanking on Xserver
		printf "xset s off &\nxset -dpms &\n$PWD/vimwa_keep_running.sh" > $HOME/.xinitrc
	fi
}
intro() {
	clear
    echo -e "Usage to launch the xserver startx ./vimwa.sh"
    echo -e ""
    echo -e "${GREEN}configure${RESTORE}           Digite isso se vc eh um ${RED}desenvolvedor novo${RESTORE}"
    echo -e ""
    echo -e "${GREEN}overwrite_xinit${RESTORE}    Copia alguns arquivos ${RED}'*.example.yml'${RESTORE} pra ${GREEN}'*.yml'${RESTORE} (sobrescreve se existir)"
    echo -e ""
    echo -e "${GREEN}dkbuild${RESTORE}           ${RED}Cria a imagem docker${RESTORE} desse projeto"
    echo -e ""
}



find_files
menu