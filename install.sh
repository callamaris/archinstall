# curl dennis/install.sh > install.sh && bash install.sh
#german keyboard layout
loadkeys de-latin1-nodeadkeys

#ask for partition size
SWAP_SIZE=16

#make partitions
sfdisk --delete /dev/sda
cat <<EOF | sfdisk /dev/sda
start= 2048, size= ${SWAP_SIZE}G, type=83
type=83, bootable 
EOF
partprobe

#make filesystem
yes | mkfs.ext4 /dev/sda2
mkswap /dev/sda1

#mount
swapon /dev/sda1
mount /dev/sda2 /mnt

#install base system
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base base-devel

cat <<EOF > /mnt/chroot.sh

passwd

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

hwclock --systohc

echo LANG=de_DE.UTF-8 > /etc/locale.conf
echo de_DE.UTF-8 UTF-8 > /etc/locale.gen
echo de_DE ISO-8859-1 >> /etc/locale.gen
echo de_DE@euro ISO-8859-15 >> /etc/locale.gen
locale-gen

echo KEYMAP=de-latin1-nodeadkeys > /etc/vconsole.conf
echo FONT=lat9w-16 >> /etc/vconsole.conf

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager

pacman --noconfirm --needed -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

EOF

arch-chroot /mnt bash chroot.sh && rm /mnt/chroot.sh

