# curl dennis/install.sh > install.sh && bash install.sh

#default settings #####################################################
ASK_OK="n"
COMP_NAME="arch"
SWAP_SIZE="16"
TIME_ZONE="Europe/Berlin"
LANG_CONF="de_DE"
LC_KEYMAP="de-latin1-nodeadkeys"
USER_NAME="${COMP_NAME}"
USER_REPO="http://dennis:8080/arch"

#customizing ##########################################################
while [ "${ASK_OK}" != "y" ]; do
  clear
  read -p "Enter a name for your computer (${COMP_NAME}): "    && if [ "${REPLY}" ]; then COMP_NAME="${REPLY}"; fi
  read -p "Enter a name for the user account (${USER_NAME}): " && if [ "${REPLY}" ]; then USER_NAME="${REPLY}"; fi
  echo "Enter a password for that new user: "
  read -s && PASS1=$REPLY
  echo
  echo "Retype password: "
  read -s && PASS2=$REPLY
  echo
  while [ "${PASS1}" != "${PASS2}" ]; do
    echo "Passwords do not match, please enter password:"
    read -s && PASS1=$REPLY
    echo
    echo "Retype password:"
    read -s && PASS2=$REPLY
    echo
  done
  read -p "Enter swap partition size, in gb (${SWAP_SIZE}): "
    if [ "${REPLY}" ]; then SWAP_SIZE="${REPLY}"; fi
  read -p "Enter your timezone (${TIME_ZONE}): "
    if [ "${REPLY}" ]; then TIME_ZONE="${REPLY}"; fi
  read -p "Enter your language (${LANG_CONF}): "
    if [ "${REPLY}" ]; then LANG_CONF="${REPLY}"; fi
  read -p "Enter your keyboard layout (${LC_KEYMAP}): "
    if [ "${REPLY}" ]; then LC_KEYMAP="${REPLY}"; fi
  echo "Enter the location of your dotfiles (${USER_REPO}): "
    read
    if [ "${REPLY}" ]; then USER_REPO="${REPLY}"; fi

  clear
  echo "Computer name      : ${COMP_NAME}"
  echo "User name          : ${USER_NAME}"
  echo "Swap partition size: ${SWAP_SIZE}"
  echo "Timezone           : ${TIME_ZONE}"
  echo "Language           : ${LANG_CONF}"
  echo "Keymap             : ${LC_KEYMAP}"
  echo "Dotfiles Repository: ${USER_REPO}"
  read -p "Are your sure, your settings are ok? [y]es, [n]o, e[x]it : " && ASK_OK="${REPLY}"
  if [ "${ASK_OK}" == "x" ]; then exit; fi
done

#confirm ##############################################################
echo "Are you sure you want to install archlinux to /dev/sda?"
echo "This will remove all existing data from your drive."
read -p "[y]es: " && if [ "${REPLY}" != "y" ]; then exit; fi

#make partitions ######################################################
sfdisk --delete /dev/sda
cat <<EOF | sfdisk /dev/sda
start= 2048, size= ${SWAP_SIZE}G, type=83
type=83, bootable 
EOF
partprobe

#make filesystem ######################################################
yes | mkfs.ext4 /dev/sda2
mkswap /dev/sda1

#mount ################################################################
swapon /dev/sda1
mount /dev/sda2 /mnt

#enable ntp ###########################################################
timedatectl set-ntp true

#install base system ##################################################
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base base-devel git networkmanager grub

#set hostname #########################################################
echo "${COMP_NAME}" > /mnt/etc/hostname

#setup system #########################################################
cat <<EOF > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

# create login user & set root password
useradd -m -g wheel -s /bin/bash "$USER_NAME"
usermod -a -G wheel "$USER_NAME"
mkdir -p /home/"$USER_NAME"
chown "$USER_NAME":wheel /home/"$USER_NAME"
echo "$USER_NAME:$PASS1" | chpasswd
echo "root:$PASS1" | chpasswd
unset PASS1 PASS2 ;

# timezone
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
hwclock --systohc

# locale
echo LANG=${LANG_CONF}.UTF-8 > /etc/locale.conf
echo ${LANG_CONF}.UTF-8 UTF-8 > /etc/locale.gen
locale-gen

# vconsole
echo KEYMAP=${LC_KEYMAP} > /etc/vconsole.conf
echo FONT=lat9w-16 >> /etc/vconsole.conf

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
grep "^Color" /etc/pacman.conf >/dev/null || sed -i "s/^#Color/Color/" /etc/pacman.conf
grep "ILoveCandy" /etc/pacman.conf >/dev/null || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

# enable services
systemctl enable NetworkManager

# grub setup
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# install aur helper
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case
echo "%wheel ALL=(ALL) NOPASSWD: ALL #ARCHINSTALL" >> /etc/sudoers
su ${USER_NAME} <<EOUSER
  # install dotfiles
  cd /home/$USER_NAME
  rm -rf .dotfiles
  git clone --bare "${USER_REPO}" ".dotfiles"
  git --git-dir=/home/${USER_NAME}/.dotfiles --work-tree=/home/${USER_NAME} checkout -f
  git --git-dir=/home/${USER_NAME}/.dotfiles --work-tree=/home/${USER_NAME} config --local status.showUntrackedFiles no
  
  # install yay
  cd /home/${USER_NAME}
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg --noconfirm -si 
  cd ..
  rm -rf yay
EOUSER

# set sudoers file
sed -i "/#ARCHINSTALL/d" /etc/sudoers
echo "%wheel ALL=(ALL) ALL #LARBS
%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm" >> /etc/sudoers
EOF

reboot


