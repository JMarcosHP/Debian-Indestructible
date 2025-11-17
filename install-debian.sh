#!/usr/bin/env bash
#
# Script to complement your Debian system
# Author: Jehu Marcos Herrera Puentes
# Original Source:
# https://github.com/coonrad/Debian-Gnome-Minimal-Install/blob/main/install-debian
#
# Usage:
# Allow execution with chmod +x
# ./install-debian.sh <parameter>
#
# Valid parameters are:
# - base
# - utilities
# - basic-server
# - gnome
# - gnome-extensions
# - gnome-apps
# - gnome-flatpak
# - gnome-snapd
# - fcitx5-support-gnome
# - kde-desktop
# - kde-flatpak
# - kde-snapd
# - fcitx5-support-kde
# - restricted-extras
# - gaming
#
# Order:
# base -> utilities -> basic-server
# base -> utilities -> DE -> extensions,apps,flatpak,snapd -> Fcitx5 (if needed) -> restricted-extras -> gaming
#
set -e

base() {
    sudo apt install -y \
		git \
		rsync \
		sudo \
		build-essential \
		meson \
		debhelper \
		vim \
		firewalld \
		needrestart \
		net-tools \
		avahi-daemon \
		firmware-linux \
		firmware-linux-nonfree \
		cryptsetup \
		cryptsetup-bin \
		cryptsetup-initramfs \
 		command-not-found \
		distro-info \
		distro-info-data \
		e2fsprogs \
		e2fsprogs-l10n \
		logrotate \
		lsb-release \
		lvm2 \
		mdadm \
		parted \
		pci.ids \
		pciutils \
		thin-provisioning-tools \
		usb.ids \
		usbmuxd \
		usbutils \
		util-linux \
		xfsprogs \
		tcpdump
}

utilities() {
    sudo apt install -y \
		7zip \
		dosfstools \
		lm-sensors \
		btop \
		ntfs-3g \
		htop \
		bzip2 \
		gzip \
		zip \
		unzip \
		libfuse2t64 \
		inxi \
		pigz \
		vainfo \
		cifs-utils \
		curl \
		xz-utils \
		tar \
		fzf \
		dkms \
		wget
}

basic-server() {
	sudo apt install -y \
		smartmontools \
		iptables \
		acl \
		bc \
		bolt \
		bpfcc-tools \
		bpftrace \
		bsdutils \
		busybox-static \
		byobu \
		cpio \
		cron \
		cron-daemon-common \
		debconf \
		debconf-i18n \
		debianutils \
		difftuils \
		dirmngr \
		dmeventd \
		dmidecode \
		dmsetup \
		eatmydata \
		ed \
		eject \
		ethtools \
		file \
		findutils \
		ftp \
		fuse3 \
		fwupd \
		fwupd-amd64-signed \
		gnupg gnupg-l10n \
		gnupg-utils \
		gpg \
		gpg-agent \
		gpg-wks-client \
		gpgconf \
		gpgsm \
		gpgv \
		groff-base \
		hdparm \
		hwdata \
		ibverbs-providers \
		ieee-data \
		inetutils-telnet \
		info \
		install-info \
		iproute2 \
		iputils-ping \
		iputils-tracepath \
		iso-codes \
		jq \
		klibc-utils \
		kmod \
		kpartx \
		krb5-locales \
		less \
		logsave \
		lshw \
		lsof \
		mawk \
		media-types \
		modemmanager \
		mtr-tiny \
		ncurses-base \
		ncurses-bin \
		ncurses-term \
		netbase \
		netcat-openbsd \
		numactl \
		open-iscsi \
		openssh-client \
		openssh-server \
		openssh-sftp-server \
		openssl \
		patch \
		perl \
		perl-base \
		perl-modules \
		pollinate \
		rpcsvc-proto \
		rsyslog \
		strace \
		ssh-import-id \
		tcl \
		tcl8.6 \
		telnet \
		thermald \
		tuned \
		tmux \
		tnftp \
		tpm-udev \
		trace-cmd \
		ucf \
		usb-modeswitch \
		usb-modeswitch-data \
		user-setup \
		uuid-runtime \
		whiptail \
		xauth \
		zerofree
}

gnome() {
    sudo apt install -y \
		desktop-base \
		adwaita-icon-theme \
		loupe \
		orca \
		tecla \
		zenity \
		pipewire-audio \
		simple-scan \
		baobab \
		file-roller \
		cups \
		cups-pk-helper \
		printer-driver-all \
		printer-driver-cups-pdf \
		printer-driver-hpijs \
		system-config-printer-common \
		system-config-printer-udev \
		fonts-cantarell \
		gdm3 \
		glib-networking \
		papers \
		gnome-snapshot \
		gnome-calculator \
		gnome-calendar \
		gnome-disk-utility \
		gnome-backgrounds \
		gnome-text-editor \
		gnome-weather \
		gnome-clocks \
		gnome-contacts \
		gnome-characters \
		gnome-browser-connector \
		gnome-color-manager \
		gnome-maps \
		gnome-menus \
		gnome-software \
		gnome-software-plugin-fwupd \
		gnome-remote-desktop \
		gnome-user-share \
		gnome-bluetooth-sendto \
		gnome-session \
		gnome-session-xsession \
		gnome-settings-daemon \
		gnome-shell \
		gnome-online-accounts \
		gnome-control-center \
		gnome-font-viewer \
		gnome-keyring \
		gnome-system-monitor \
		gsettings-desktop-schemas \
		gnome-logs \
		gnome-terminal \
		gnome-tweaks \
		yelp \
		gnome-user-docs \
		nautilus \
		nautilus-share \
		nautilus-wipe \
		nautilus-extension-gnome-terminal \
		ffmpegthumbnailer \
		gnome-sushi \
		qgnomeplatform-qt5 \
		qgnomeplatform-qt6 \
		gstreamer1.0-packagekit \
		gstreamer1.0-plugins-base \
		gstreamer1.0-plugins-good \
		gvfs-backends \
		gvfs-fuse \
		libatk-adaptor \
		libcanberra-pulse \
		libglib2.0-bin \
		libpam-gnome-keyring \
		libgsf-bin \
		locales-all \
		low-memory-monitor \
		rygel-playbin \
		rygel-tracker \
		avahi-daemon \
		network-manager \
		network-manager-l10n \
		network-manager-openvpn \
		network-manager-openvpn-gnome \
		network-manager-l2tp \
		network-manager-l2tp-gnome \
		network-manager-iodine \
		network-manager-iodine-gnome \
		network-manager-openconnect \
		network-manager-openconnect-gnome \
		network-manager-pptp \
		network-manager-pptp-gnome \
		network-manager-ssh \
		network-manager-ssh-gnome \
		network-manager-sstp \
		network-manager-sstp-gnome \
		network-manager-strongswan \
		network-manager-vpnc \
		network-manager-vpnc-gnome \
		wl-clipboard \
		xsel \
		xdg-user-dirs \
		xdg-utils

	sudo usermod -aG lpadmin,scanner $USER
    echo "QT_QPA_PLATFORMTHEME=gnome" | sudo tee -a /etc/environment.d/90qt.conf > /dev/null
}

gnome-extensions() {
    sudo apt install --no-install-recommends -y \
		gnome-shell-extensions \
		gnome-shell-extensions-common \
		gnome-shell-extensions-extra
}

gnome-apps() {
    sudo apt install -y \
		firewall-config \
		ptyxis \
		synaptic
}

gnome-flatpak() {
    sudo apt install -y \
		gnome-software-plugin-flatpak \
		flatpak

    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

gnome-snapd() {
    sudo apt install -y \
		gnome-software-plugin-snap \
		snapd

    sudo systemclt enable --now snapd
}

fcitx5-support-gnome() {
    sudo apt install --install-recommends -y \
		fcitx5 \
		fcitx5-chinese-addons \
		fcitx5-chewing \
		fcitx5-mozc \
		fcitx5-skk \
		fcitx5-hangul \
		fcitx5-rime \
		fcitx5-libthai \
		gnome-shell-extension-kimpanel

    sudo apt remove uim uim-mozc
}

kde-desktop() {
    sudo apt install -y \
		plasma-desktop \
		plasma-workspace \
		plasma-integration \
		plasma-activities-bin \
		systemsettings \
		kde-inotify-survey \
		kwin-x11 \
		sddm \
		webext-plasma-browser-integration \
		udisks2 \
		upower \
		gstreamer1.0-qt5 \
		gstreamer1.0-qt6 \
		xserver-xorg \
		xserver-xorg-input-all \
		xserver-xorg-video-all \
		kdeconnect \
		dolphin \
		dolphin-plugins \
		kdialog \
		kfind \
		konsole \
		kate \
		kcalc \
		khelpcenter \
		okular \
		filelight \
		kcharselect \
		kdf \
		print-manager \
		cups \
		system-config-printer-common \
		system-config-printer-udev \
		printer-driver-all \
		printer-driver-cups-pdf \
		printer-driver-hpijs \
		smbclient \
		caffeine \
		ark \
		skanlite \
		gwenview \
		kwalletmanager \
		kde-config-cron \
		kwin-addons \
		ksystemlog \
		kamera \
		kamoso \
		kcolorchooser \
		kmag \
		kaccounts-integration \
		kaccounts-providers \
		kio-admin \
		kio-gdrive \
		kio-ldap \
		ffmpegthumbs \
		kdegraphics-thumbnailers \
		svgpart \
		plasma-desktoptheme \
		plasma-disks \
		plasma-dataengines-addons \
		plasma-pa \
		plasma-nm \
		plasma-wayland-protocols \
		plasma-runners-addons \
		plasma-widgets-addons \
		plasma-wallpapers-addons \
		plasma-workspace-wallpapers \
		plasma-systemmonitor \
		plasma-thunderbolt \
		plasma-discover \
		plasma-discover-common \
		plasma-discover-backend-fwupd \
		plasma-firewall \
		plasma-gamemode \
		plasma-calendar-addons \
		plasma-gmailfeed \
		polkit-kde-agent-1 \
		kde-spectacle \
		kde-config-gtk-style \
		kde-config-gtk-style-preview \
		kde-config-plymouth \
		kde-config-tablet \
		kde-config-cddb \
		colord-kde \
		qt-style-kvantum \
		qt-style-kvantum-l10n \
		network-manager \
		network-manager-l10n \
		network-manager-iodine \
		network-manager-l2tp \
		network-manager-openconnect \
		network-manager-openvpn \
		network-manager-pptp \
		network-manager-ssh \
		network-manager-strongswan \
		network-manager-vpnc \
		wl-clipboard \
		xsel \
		xdg-user-dirs \
		xdg-utils

    sudo usermod -aG lpadmin,scanner $USER
}

kde-flatpak() {
    sudo apt install -y \
		plasma-discover-backend-flatpak \
		kde-config-flatpak \
		flatpak

    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

kde-snapd() {
    sudo apt install -y \
		plasma-discover-backend-snap \
		snapd

    sudo systemctl enable --now snapd
}

fcitx5-support-kde() {
    sudo apt install --install-recommends -y \
		fcitx5 \
		fcitx5-chinese-addons \
		fcitx5-chewing \
		fcitx5-mozc \
		fcitx5-skk \
		fcitx5-hangul \
		fcitx5-rime \
		fcitx5-libthai \
		kde-config-fcitx5

    sudo apt remove uim uim-mozc
}

restricted-extras() {
    sudo apt install -y \
		libdvd-pkg \
		libdvdcss2 \
		libavcodec-extra \
		lame \
		gstreamer1.0-gl \
		gstreamer1.0-plugins-bad \
		gstreamer1.0-plugins-ugly \
		gstreamer1.0-plugins-good \
		gstreamer1.0-plugins-base \
		gstreamer1.0-vaapi \
		gstreamer1.0-libav \
		libk3b-extracodecs \
		ttf-mscorefonts-installer \
		rar \
		unrar

    sudo dpkg-reconfigure libdvd-pkg
}

gaming() {
    sudo apt install -y \
		mangohud \
		gamemode \
		gamemode-daemon \
		gamescope \
		vkbasalt

	wget -P /tmp https://cdn.akamai.steamstatic.com/client/installer/steam.deb
	sudo apt install -y /tmp/steam.deb
	rm -r /tmp/steam.deb
	echo 'ntsync' | sudo tee -a  /etc/modules-load.d/ntsync.conf > /dev/null
}

if [[ $(uname) == 'Linux' ]]; then
    if [ "$(/bin/grep ^ID= /etc/os-release)" = "ID=debian" ]; then
        "$@" && echo
    fi
fi
