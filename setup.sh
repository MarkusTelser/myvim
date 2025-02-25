#!/usr/bin/env bash

HOME=$1
CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="${CDIR}/backup"
backup_files=()

# ------------------
# UTILITY FUNCTIONS
# ------------------

function _print(){
    if [ $# == 2 ]; then case $2 in
            0) icon="\u2713"; color="\u001b[32m";; # success
            1) icon="\u0021"; color="\u001b[33m";; # warning
            2) icon="\u0078"; color="\u001b[31m";; # error
        esac
        COLOR_SUPPORT=$(tput colors 2> /dev/null)
        if [ $? = 0 ] && [ $COLOR_SUPPORT -gt 2 ]; then
            echo -e "$color- [$icon] $1\u001b[0m"
        else
            echo -e "- [ $icon ] $1"
        fi
    fi
}

function _prepareSymLink(){
		# make source file executable	
		if [ "$3" == "1" ]; then
			sudo -u root chmod +x "$1"
		fi

		# is symlink
    if [ -h "$2" ]; then
				_print "updating existing symlink at $2 (to $1)" 1
        rm $2
		# is normal file
		elif [ -e "$2" ]; then
				cd $CDIR && sudo -u $RUSER mkdir -p $BACKUP_DIR

				# if directory exists and is not empty
        if [[ -d "$2" ]] && [[ ! -z "$(ls -A "$2")" ]]; then
            _print "removing existing directory $2" 2
						backup_files+=("$2")
        elif [[ -f "$2" ]]; then
            _print "removing existing file $2" 2
		        backup_files+=("$2")
        fi
				cp -RL $2 $BACKUP_DIR && rm -rf $2
		else
				_print "creating symlink at $2 (to $1)" 0
		fi
}

function createUserSymLink(){
	_prepareSymLink "$@"
	sudo -u $RUSER ln -s $1 $2
}

function createRootSymLink(){
	_prepareSymLink "$@"
	sudo -u root ln -s $1 $2
}

function update_sys {
    if [ -x "$(command -v pacman)" ]; then
        pacman --noconfirm -Syu 1> /dev/null
    elif [ -x "$(command -v apt-get)" ]; then
        apt-get -y update 1> /dev/null
        apt-get -y dist-upgrade 1> /dev/null
    else
        echo "No supported package manager!"
        exit 1
    fi
}


# ------------------
# MODULE FUNCTIONS 
# ------------------ 
# "alacritty" "bash" "zsh" "tmux" "nvim" "i3" "scripts"

function pre_modules {
	if [[ ! -d $HOME/.config ]]; then
		sudo -u $RUSER mkdir -p $HOME/.config
	fi

	# exit if package-manager lock can't be is acquired
	if [ -x "$(command -v pacman)" ] && ! pacman --noconfirm -Sy &> /dev/null ; then
			echo "pacman lock can not be acquired!"
			exit 1
	elif [ -x "$(command -v apt-get)" ] && ! apt-get -y install &> /dev/null ; then
			echo "apt-get lock can not be acquired!"
			exit 1
	fi 

	# install fonts if one of following modules is present 
	if [[ "${modules[*]}" =~ "alacritty" ]] \
	|| [[ "${modules[*]}" =~ "bash" ]] \
	|| [[ "${modules[*]}" =~ "zsh" ]] \
	|| [[ "${modules[*]}" =~ "i3" ]]; then
		if [ -x "$(command -v pacman)" ]; then
			pacman --noconfirm -S curl ttf-dejavu
		elif [ -x "$(command -v apt-get)" ]; then
			apt-get -y install curl
		fi	

		sudo -u $RUSER mkdir -p $HOME/.local/share/fonts
		cd $HOME/.local/share/fonts

		# install SourceCodePro Regular Semibold Italic Semibold-Italic
		sudo -u $RUSER mkdir -p SourceCodePro && cd SourceCodePro
		sudo -u $RUSER curl -fLo "Source Code Pro Regular Nerd Font Complete.ttf"\
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "Source Code Pro Regular Nerd Font Complete-Mono.ttf"\
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete%20Mono.ttf
		sudo -u $RUSER curl -fLo "Source Code Pro Semibold Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Semibold/complete/Sauce%20Code%20Pro%20Semibold%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "Source Code Pro Semibold Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Semibold/complete/Sauce%20Code%20Pro%20Semibold%20Nerd%20Font%20Complete%20Mono.ttf
		sudo -u $RUSER curl -fLo "Source Code Pro Italic Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Italic/complete/Sauce%20Code%20Pro%20Italic%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "Source Code Pro Italic Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Italic/complete/Sauce%20Code%20Pro%20Italic%20Nerd%20Font%20Complete%20Mono.ttf
		sudo -u $RUSER curl -fLo "Source Code Pro Semibold Italic Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Semibold-Italic/complete/Sauce%20Code%20Pro%20Semibold%20Italic%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "Source Code Pro Semibold Italic Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/SourceCodePro/Semibold-Italic/complete/Sauce%20Code%20Pro%20Semibold%20Italic%20Nerd%20Font%20Complete%20Mono.ttf
		cd ../

		# install DejaVuSansMono Regular Bold Italic Bold-Italic
		sudo -u $RUSER mkdir -p DejaVuSansMono && cd DejaVuSansMono
		sudo -u $RUSER curl -fLo "DejaVu Sans Mono Regular Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Regular/complete/DejaVu%20Sans%20Mono%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "DejaVu Sans Mono Regular Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Regular/complete/DejaVu%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.ttf	
		sudo -u $RUSER curl -fLo "DejaVu Sans Mono Bold Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Bold/complete/DejaVu%20Sans%20Mono%20Bold%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "DejaVu Sans Mono Bold Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Bold/complete/DejaVu%20Sans%20Mono%20Bold%20Nerd%20Font%20Complete%20Mono.ttf
		sudo -u $RUSER curl -fLo "DejaVu Sans Mono Italic Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Italic/complete/DejaVu%20Sans%20Mono%20Oblique%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "DejaVu Sans Mono Italic Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Italic/complete/DejaVu%20Sans%20Mono%20Oblique%20Nerd%20Font%20Complete%20Mono.ttf
		sudo -u $RUSER curl -fLo "DejaVu Sans Mono Bold Italic Nerd Font Complete.ttf" \
			https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Bold-Italic/complete/DejaVu%20Sans%20Mono%20Bold%20Oblique%20Nerd%20Font%20Complete.ttf
		# sudo -u $RUSER curl -fLo "DejaVu Sans Mono Bold Italic Nerd Font Complete-Mono.ttf" \
		# 	https://github.com/ryanoasis/nerd-fonts/raw/v2.2.2/patched-fonts/DejaVuSansMono/Bold-Italic/complete/DejaVu%20Sans%20Mono%20Bold%20Oblique%20Nerd%20Font%20Complete%20Mono.ttf
	fi

	# install fzf,neofetch,aliases,dircolors if one of following modules is present 
	if [[ "${modules[*]}" =~ "bash" ]] \
	|| [[ "${modules[*]}" =~ "zsh" ]]; then
		if [ -x "$(command -v pacman)" ]; then
			pacman --noconfirm -S fzf neofetch
		elif [ -x "$(command -v apt-get)" ]; then
			apt-get -y install fzf neofetch	
		fi

		createUserSymLink $CDIR/aliases/aliasrc $HOME/.config/aliasrc
		createUserSymLink $CDIR/aliases/paliasrc $HOME/.config/paliasrc
		createUserSymLink $CDIR/dircolors/dir_colors $HOME/.dircolors
	fi
}

function alacritty {
	# install terminal (alacritty)
	if [ -x "$(command -v pacman)" ]; then
		pacman --noconfirm -S alacritty
	elif [ -x "$(command -v apt-get)" ]; then
		add-apt-repository -y ppa:aslatter/ppa
		apt-get -y update
		apt-get -y install alacritty 
	fi
	
	createUserSymLink "$CDIR/alacritty/" "$HOME/.config/alacritty"
	createRootSymLink "/usr/bin/alacritty" "/usr/bin/terminal"
}


function bash {
	if [ -x "$(command -v pacman)" ]; then
		pacman --noconfirm -S bash
	elif [ -x "$(command -v apt-get)" ]; then
		apt-get -y install bash
	fi
	
	createUserSymLink $CDIR/bash/bashrc $HOME/.bashrc
	createUserSymLink $CDIR/bash/bash_prompt $HOME/.bash_prompt
	createUserSymLink $CDIR/bash/bash_profile $HOME/.bash_profile
}

function zsh {
	if [ -x "$(command -v pacman)" ]; then
		pacman --noconfirm -S zsh zsh-completions git
	elif [ -x "$(command -v apt-get)" ]; then
		apt-get -y install zsh git
	fi

	sudo -u $RUSER \
		git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

	if [[ ! -d $HOME/.config/zsh ]]; then
		sudo -u $RUSER mkdir -p $HOME/.config/zsh
	fi
	
	createUserSymLink $CDIR/zsh/zshenv $HOME/.zshenv
	createUserSymLink $CDIR/zsh/zshrc $HOME/.config/zsh/.zshrc
	createUserSymLink $CDIR/zsh/zsh_prompt $HOME/.config/zsh/.zsh_prompt
	createUserSymLink $CDIR/zsh/plugins $HOME/.config/zsh/.plugins
}

function tmux {
	if [ -x "$(command -v pacman)" ]; then
		pacman --noconfirm -S tmux
	elif [ -x "$(command -v apt-get)" ]; then
		apt-get -y install tmux
	fi

	createUserSymLink $CDIR/tmux $HOME/.config/tmux
}

function nvim {
	# install neovim through official distro repos
	if [ -x "$(command -v pacman)" ]; then
    pacman --noconfirm -S neovim nodejs go clang python3 python-pip base-devel fd ripgrep
	elif [ -x "$(command -v apt-get)" ]; then
		add-apt-repository -y ppa:neovim-ppa/stable
		apt-get -y update
		apt-get -y install neovim nodejs golang clangd python3 python3-pip build-essential fd-find ripgrep
		createRootSymLink $(which fdfind) ~/.local/bin/fd
		# WARNING: Make sure that $HOME/.local/bin is in your $PATH
	fi
	sudo -u $RUSER pip3 install pyright

	# install nvim plugin manager "plug"
	sudo -u $RUSER curl -fLo ~/.local/share/nvim/site/autoload/plug.vim \
		--create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

	createUserSymLink $CDIR/nvim $HOME/.config/nvim

	sudo -u $RUSER nvim +PlugInstall +qall
}

# TODO test setup
function i3 {
	if [ -x "$(command -v pacman)" ]; then
    pacman --noconfirm -S dmenu # breaks dependencys with dmenu-manjaro
    pacman --noconfirm -S i3status # breaks dependencys with i3status-manjaro
    pacman --noconfirm -S xdg-utils xdg-user-dirs # TODO: check if alright
    pacman --noconfirm -S i3-wm i3-gaps i3lock i3blocks feh picom udiskie flameshot
	elif [ -x "$(command -v apt-get)" ]; then
		apt-get -y install i3 dmenu feh picom udiskie flameshot xdg-utils xdg-user-dirs
	fi

	## install packages from AUR if paru is installed
	if [ -x "$(command -v paru)" ]; then
		paru --noconfirm -S dmenu-extended-git
	fi

	sudo -u $RUSER mkdir -p $HOME/.config/i3
	sudo -u $RUSER mkdir -p $HOME/.config/i3status
	sudo -u $RUSER mkdir -p $HOME/.config/flameshot

	createUserSymLink $CDIR/i3/picom.conf $HOME/.config/picom.conf
	createUserSymLink $CDIR/i3/config $HOME/.config/i3/config
	createUserSymLink $CDIR/i3/i3status $HOME/.config/i3status/config
	createUserSymLink $CDIR/i3/flameshot.ini $HOME/.config/flameshot/flameshot.ini
	createUserSymLink $CDIR/i3/xinitrc $HOME/.xinitrc
	createUserSymLink $CDIR/i3/dmenurc $HOME/.dmenurc
	createUserSymLink $CDIR/i3/dmenuExtended_preferences.txt $HOME/.config/dmenu-extended/config/dmenuExtended_preferences.txt

	createRootSymLink "$CDIR/i3/user-dirs.defaults" "/etc/xdg/user-dirs.defaults"
	createRootSymLink "$CDIR/i3/slick-greeter.conf" "/etc/lightdm/slick-greeter.conf"
	createRootSymLink "$CDIR/i3/lightdm.conf" "/etc/lightdm/lightdm.conf"
	createRootSymLink "$CDIR/i3/home-local-bin.sh" "/etc/profile.d/home-local-bin.sh" 1
	createRootSymLink "$CDIR/i3/70-touchpad.conf" "/etc/X11/xorg.conf.d/70-touchpad.conf"

	createRootSymLink "$CDIR/i3/i3exit" "/usr/bin/i3exit" 1
	createRootSymLink "$CDIR/i3/i3exit" "/bin/i3exit" 1
		
	# download background-wallpapers into '~/Pictures/i3-wallpapers'
	sudo -u $RUSER mkdir -p $HOME/Pictures/i3-wallpapers
	cd $HOME/Pictures/i3-wallpapers
	curl -fLo "layered-mountain-view.jpg" "https://images.pexels.com/photos/1323550/pexels-photo-1323550.jpeg?cs=srgb&dl=pexels-simon-berger-1323550.jpg&fm=jpg&w=4608&h=2963"
	curl -fLo "seiser-alm.jpg" "https://backiee.com/static/wpdb/wallpapers/3840x2160/190580.jpg"
	curl -fLo "promontory-point-chicago.png" "https://i.redd.it/t7v63cixnni91.png"
	curl -fLo "green-rice-field-sky.jpg" "https://images.pexels.com/photos/1146708/pexels-photo-1146708.jpeg?cs=srgb&dl=pexels-johannes-plenio-1146708.jpg&fm=jpg&w=5068&h=2850"
	curl -fLo "appenzell-mountain-range.jpg" "https://4kwallpapers.com/images/wallpapers/appenzell-alps-switzerland-mountain-range-glacier-mountains-4979x3320-6397.jpg"
	curl -fLo "alpstein-mountain-range.jpg" "https://4kwallpapers.com/images/wallpapers/alpstein-switzerland-mountain-range-landscape-foggy-aerial-3840x2400-4257.jpg"

	# download slick-greeter background
	mkdir -p /usr/share/backgrounds
	curl -fLo "/usr/share/backgrounds/slick-greeter-background.jpg" "https://besthqwallpapers.com/Uploads/21-9-2020/141561/black-geometric-shapes-4k-geometric-patterns-wavy-backgrounds-3d-figures.jpg"
}

function scripts {
	if [[ ! -d $HOME/.local/bin ]]; then
		sudo -u $RUSER mkdir -p $HOME/.local/bin
	fi

	if [ -x "$(command -v pacman)" ]; then
    pacman --noconfirm -S bat xdotool gawk sed bc jq imagemagick
	elif [ -x "$(command -v apt-get)" ]; then
		apt-get -y install bat xdotool gawk sed bc jq imagemagick
		# on debian or ubuntu bat useses the batcat command by default
		createUserSymLink /usr/bin/batcat $HOME/.local/bin/bat
	fi

	for filename in $CDIR/scripts_user/*; do
		createUserSymLink $filename $HOME/.local/bin/$(basename ${filename%.sh}) 1
	done
	for filename in $CDIR/scripts_root/*; do
		createRootSymLink $filename /usr/bin/$(basename ${filename%.sh}) 1
		createRootSymLink $filename /bin/$(basename ${filename%.sh}) 1
	done
}

# -------------
# MAIN SCRIPT
# -------------

# require root priviledges for package installations/updates
if [ "$EUID" -ne 0 ]; then
    echo "Please run script as root!"
    exit 1
fi

# get real user
if [ $SUDO_USER ]; then
    RUSER=$SUDO_USER
else
    RUSER=$(whoami)
fi

# accept only exectution with one param
if (( "$#" != 1 )); then
    echo "Invalid number of parameters"
    echo "Usage: ./script.sh <HOME_DIR>"
    exit 1
fi

modules=("alacritty" "bash" "zsh" "tmux" "nvim" "i3" "scripts")
echo "Available modules: ${modules[@]}"
read -p "Do you want to install all? Include/Exclude some? [AIE] " uinput

case ${uinput:0:1} in 
	a|A ) ;;
	i|I ) 
		read -p "Modules to include: " uinput
		for i in ${modules[@]}; do
			test=0
			for j in ${uinput[@]}; do 
				[[ $i == $j ]] && test=1
			done
			[[ $test -eq 0 ]] && modules=("${modules[@]/$i}")
		done ;;
	e|E ) 
		read -p "Modules to exclude: " uinput
		for del in ${uinput[@]}; do
			 modules=("${modules[@]/$del}") 
		done ;;
	* ) exit 1;; 
esac

echo "Selected modules: " ${modules[@]} | xargs
read -p "Are you sure? [Y/n] " uinput
case ${uinput:0:1} in 
	y|Y ) ;;
	* ) exit 1;; 
esac

# update_sys
pre_modules

# call functions of selected modules
for module_func in ${modules[@]}; do
	$module_func
done

# inform user about count of backed-up files
echo
if [[ ${#backup_files[@]} -gt 0 ]]; then
	echo "${#backup_files[@]} files backed up into $BACKUP_DIR"
	for item in "${backup_files[@]}"; do
			echo "- $item"
	done
else
	echo "No files backed up into $BACKUP_DIR"
fi

echo 
echo "For changes to take affect,"
echo "you have to open a new terminal instance or"
echo "'source ~/.bashrc' and 'source ~/.config/zsh/.zshrc'"
