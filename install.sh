# curl dennis/install.sh > install.sh && bash install.sh

#default settings #####################################################
ASK_OK="n"
COMP_NAME="mycomputer"
SWAP_SIZE="16"
TIME_ZONE="Europe/Berlin"
LANG_CONF="de_DE"
LC_KEYMAP="de-latin1-nodeadkeys"

#customizing ##########################################################
while [ "${ASK_OK}" != "y" ]; do
  clear
  read -p "Enter a name for your computer (${COMP_NAME}): "   && if [ "${REPLY}" ]; then COMP_NAME="${REPLY}"; fi
  read -p "Enter swap partition size, in gb (${SWAP_SIZE}): " && if [ "${REPLY}" ]; then SWAP_SIZE="${REPLY}"; fi
  read -p "Enter your timezone (${TIME_ZONE}): "              && if [ "${REPLY}" ]; then TIME_ZONE="${REPLY}"; fi
  read -p "Enter your language (${LANG_CONF}): "              && if [ "${REPLY}" ]; then LANG_CONF="${REPLY}"; fi
  read -p "Enter your keyboard layout (${LC_KEYMAP}): "       && if [ "${REPLY}" ]; then LC_KEYMAP="${REPLY}"; fi

  clear
  echo "Computer name      : ${COMP_NAME}"
  echo "Swap partition size: ${SWAP_SIZE}"
  echo "Timezone           : ${TIME_ZONE}"
  echo "Language           : ${LANG_CONF}"
  echo "Keymap             : ${LC_KEYMAP}"
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
pacstrap /mnt base base-devel

#set hostname #########################################################
echo "${COMP_NAME}" > /mnt/etc/hostname

#setup system #########################################################
cat <<EOF > /mnt/chroot.sh && arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh
#passwd

ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

hwclock --systohc

echo LANG=${LANG_CONF}.UTF-8 > /etc/locale.conf
echo ${LANG_CONF}.UTF-8 UTF-8 > /etc/locale.gen
echo ${LANG_CONF} ISO-8859-1 > /etc/locale.gen
locale-gen

echo KEYMAP=${LC_KEYMAP} > /etc/vconsole.conf
echo FONT=lat9w-16 >> /etc/vconsole.conf

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager

pacman --noconfirm --needed -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

EOF


