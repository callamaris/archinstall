#german keyboard layout
loadkeys de-latin1-nodeadkeys

#ask for partition size
read -p "Enter swap partition size: "
SWAP_SIZE=$REPLY
read -p "Enter root partition size: "
ROOT_SIZE=$REPLY

#make filesystem
cat <<EOF | fdisk /dev/sda
o
n
p


+200M
n
p


+${SWAP_SIZE}G
n
p
+${ROOT_SIZE}G
n
p



w
EOF
yes | mkfs.ext4 /dev/sda4
yes | mkfs.ext4 /dev/sda3
yes | mkfs.ext4 /dev/sda1

#mount
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home


