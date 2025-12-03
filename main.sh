#!/bin/bash

SETUP_DISTRO="false"
DESKTOP_ENVIRONMENT="unknown"
INSTALL_BUN="default"
INSTALL_VM="default"
INSTALL_KDE_CONNECT="default"

for arg in "$@"; do
  if [ "$arg" = "--setup" ]; then
    PREPARE_DISTRO="true"
  elif [ "$arg" = "--install-bun" ]; then
    INSTALL_BUN="true"
  elif [ "$arg" = "--install-vm" ]; then
    INSTALL_VM = "true"
  elif [ "$arg" = "--install-kde-connect" ]; then
    INSTALL_KDE_CONNECT="true"
  else
    echo "The argumment $arg is not supported."
    exit 1
  fi
done

if [ "$SETUP_DISTRO" = "true" ]; then
  while [ "$DESKTOP_ENVIRONMENT" = "unknown" ]; do
    read -p "What is your desktop environment? [gnome/kde/cinnamon/xfce]: " INPUT
    [ "$INPUT" = "gnome" ] && DESKTOP_ENVIRONMENT="$INPUT"
    [ "$INPUT" = "kde" ] && DESKTOP_ENVIRONMENT="$INPUT"
    [ "$INPUT" = "cinnamon" ] && DESKTOP_ENVIRONMENT="$INPUT"
    [ "$INPUT" = "xfce" ] && DESKTOP_ENVIRONMENT="$INPUT"

    if [ "$DESKTOP_ENVIRONMENT" = "unknown" ]; then
      echo "Invalid choise, chose one of the desktop environments of the list."
    fi
  done
  while [ "$INSTALL_BUN" = "default" ]; do
    read -p "Do you want to install bun? [Y/n]: " INPUT
    [ "$INPUT" = "" ] && INSTALL_BUN="true"
    [ "$INPUT" = "y" ] && INSTALL_BUN="true"
    [ "$INPUT" = "n" ] && INSTALL_BUN="false"
    [ "$INPUT" = "Y" ] && INSTALL_BUN="true"
    [ "$INPUT" = "N" ] && INSTALL_BUN="false"

    if [ "$INSTALL_BUN" = "default" ]; then
      echo "Invalid choise."
    fi
  done
  while [ "$INSTALL_VM" = "default" ]; do
    read -p "Do you want to install kvm, qemu and virt manager? [Y/n]: " INPUT
    [ "$INPUT" = "" ] && INSTALL_VM="true"
    [ "$INPUT" = "y" ] && INSTALL_VM="true"
    [ "$INPUT" = "n" ] && INSTALL_VM="false"
    [ "$INPUT" = "Y" ] && INSTALL_VM="true"
    [ "$INPUT" = "N" ] && INSTALL_VM="false"

    if [ "$INSTALL_VM" = "default" ]; then
      echo "Invalid choise."
    fi
  done
  while [ "$INSTALL_KDE_CONNECT" = "default" ]; do
    read -p "Do you want to install kde connect? [Y/n]: " INPUT
    [ "$INPUT" = "" ] && INSTALL_KDE_CONNECT="true"
    [ "$INPUT" = "y" ] && INSTALL_KDE_CONNECT="true"
    [ "$INPUT" = "n" ] && INSTALL_KDE_CONNECT="false"
    [ "$INPUT" = "Y" ] && INSTALL_KDE_CONNECT="true"
    [ "$INPUT" = "N" ] && INSTALL_KDE_CONNECT="false"

    if [ "$INSTALL_KDE_CONNECT" = "default" ]; then
      echo "Invalid choise."
    fi
  done
else
  [ "$INSTALL_BUN" = "default" ] && INSTALL_BUN="false"
  [ "$INSTALL_VM" = "default" ] && INSTALL_VM="false"
  [ "$INSTALL_KDE_CONNECT" = "default" ] && INSTALL_KDE_CONNECT="false"
fi

sudo apt update
sudo apt install -y curl wget apt-transport-https

if [ "$SETUP_DISTRO" = "true" ]; then
  # Brave Browser
  if ! command -v brave-browser >/dev/null 2>&1; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  fi

  # VSCode
  sudo apt-get install wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
  sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
  rm -f microsoft.gpg

  sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

  # Nodejs
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

  # Only Office
  wget -O onlyoffice-desktopeditors_amd64.deb https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors_amd64.deb

  # Git Credential Manager
  wget -O gcm-linux_amd64.deb https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb

  # Installing Packages
  PACKAGES="vlc code git brave-browser nodejs samba"

  if ! [ "$DESKTOP_ENVIRONMENT" = "kde" ]; then
    PACKAGES="$PACKAGES qt5ct"
  fi

  if [ "$INSTALL_KDE_CONNECT" = "true" ]; then
    PACKAGES="$PACKAGES kdeconnect"
  fi

  sudo apt update
  sudo apt install -y $PACKAGES
  sudo apt install -y ./onlyoffice-desktopeditors_amd64.deb
  sudo apt install -y ./gcm-linux_amd64.deb
  sudo apt purge firefox firefox* libreoffice libreoffice* -y
  sudo apt autoremove --purge -y

  # Removing Leftovers
  rm onlyoffice-desktopeditors_amd64.deb
  rm gcm-linux_amd64.deb
  sudo rm -rf .mozilla

  # Git Configuration
  git config --global user.name "leo20481141"
  git config --global user.email "newleovera14122019@gmail.com"
  git config --global core.editor "code --wait"
  git config --global core.autocrlf "input"

  # Git Credential Manager Configuration
  git-credential-manager configure
  git config --global credential.credentialStore secretservice
fi

if [ "$INSTALL_BUN" = "true" ]; then
  curl -fsSL https://bun.sh/install | bash
fi

if [ "$INSTALL_VM" = "true" ]; then
  sudo apt install qemu-system-x86 libvirt-daemon-system virtinst \
    virt-manager virt-viewer ovmf swtpm qemu-utils guestfs-tools \
    libosinfo-bin -y
  sudo systemctl enable libvirtd.service
  sudo usermod -aG libvirt $USER
  echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
  CMDLINE_NORMAL_PREFIX="GRUB_CMDLINE_LINUX="
  CMDLINE_DEFAULT_PREFIX="GRUB_CMDLINE_LINUX_DEFAULT="
  CMDLINE_NORMAL=$(grep "$CMDLINE_NORMAL_PREFIX" "/etc/default/grub")
  CMDLINE_DEFAULT=$(grep "$CMDLINE_DEFAULT_PREFIX" "/etc/default/grub")
  CMDLINE_NORMAL_END=0
  CMDLINE_DEFAULT_END=0
  TMP_COUNT=0
  for ((i=0;i<${#CMDLINE_NORMAL};i++)); do
    if [ "${CMDLINE_NORMAL:i:1}" = "\"" ]; then
      ((TMP_COUNT++))
    fi
    if [ "$TMP_COUNT" = "2" ]; then
      CMDLINE_NORMAL_END=$i
      ((TMP_COUNT++))
    fi
  done
  TMP_COUNT=0
  for ((i=0;i<${#CMDLINE_DEFAULT};i++)); do
    if [ "${CMDLINE_DEFAULT:i:1}" = "\"" ]; then
      ((TMP_COUNT++))
    fi
    if [ "$TMP_COUNT" = "2" ]; then
      CMDLINE_DEFAULT_END=$i
      ((TMP_COUNT++))
    fi
  done
  CMDLINE_NORMAL_LENGTH=$(( CMDLINE_NORMAL_END - ${#CMDLINE_NORMAL_PREFIX} ))
  CMDLINE_DEFAULT_LENGTH=$(( CMDLINE_DEFAULT_END - ${#CMDLINE_DEFAULT_PREFIX} ))
  WRITE_TO="default"
  if [ "$CMDLINE_NORMAL_LENGTH" -gt "$CMDLINE_DEFAULT_LENGTH" ]; then
    WRITE_TO="normal"
  fi
  CMDLINE_NORMAL_NEW="${CMDLINE_NORMAL:0:$CMDLINE_NORMAL_END} intel_iommu=on iommu=pt${CMDLINE_NORMAL:$CMDLINE_NORMAL_END}"
  CMDLINE_DEFAULT_NEW="${CMDLINE_DEFAULT:0:$CMDLINE_DEFAULT_END} intel_iommu=on iommu=pt${CMDLINE_DEFAULT:$CMDLINE_DEFAULT_END}"
  if [ "$WRITE_TO" = "normal" ]; then
    sed -i "s/^${CMDLINE_NORMAL}$/${CMDLINE_NORMAL_NEW}" "/etc/default/grub"
  fi
  if [ "$WRITE_TO" = "default" ]; then
    sed -i "s/^${CMDLINE_DEFAULT}$/${CMDLINE_DEFAULT_NEW}" "/etc/default/grub"
  fi
  update-grub
fi

echo "@neutralinojs/neu"
