#!/bin/bash

# Show disk information

lsblk


# Select disk and partition to perform

read -p "Choose your disk to increase: (sda,sdb,sdc,...): " disk
read -p "Choose your partition of disk $disk to increase: (1,2,3,...): " partition

# Rescan disk and partition
echo 1>/sys/class/block/${disk}/device/rescan

# Check partition is the last one
last_part=`lsblk -l | grep $disk | tail -n 1 | awk '{print $1}'`

if [ "$last_part" == "${disk}${partition}" ]; then
        echo "Select FileSystem to extend or expand: "
        df -hT | nl
        read -p "Your choice: " select
        fs=`df -hT | head -n $select | tail -n 1 | awk '{print $1}'`
        echo "You are going to increase capacity for $fs"

        # Check partition type LVM or not
        if lsblk -no TYPE /dev/${disk}${partition} | grep lvm > /dev/null ; then

                # Get Logical Volume and Volume Group information
                lv_path=`lvdisplay $fs | head -n 2 | tail -n 1 | awk '{print $3}'`
                lv_name=`lvdisplay $fs | head -n 3 | tail -n 1 | awk '{print $3}'`
                vg_name=`lvdisplay $fs | head -n 4 | tail -n 1 | awk '{print $3}'`

                echo "Your lv path: $lv_path"
                echo "Your lv name: $lv_name"
                echo "Your vg name: $vg_name"

                # Install "gdisk" and "parted" tools

                yum install -y gdisk parted > /dev/null
                apt install -y gdisk parted > /dev/null

                # Rebuild disk block
                sgdisk -e /dev/$disk
                partprobe

                # Increase partition capacity
                parted /dev/$disk resizepart $partition 100%

                # Increase Physical Volume capacity
                pvresize /dev/${disk}${partition}

                # Increase Logical Volume capacity
                lvextend -l +100%FREE $lv_path

                # Check FileSystem TYPE XFS or EXT4
                fs_type=`blkid -o value -s TYPE $lv_path`

                if [ $fs_type == "xfs" ]; then
                        xfs_growfs $lv_path
                else
                        resize2fs $lv_path
                fi

                df -hT

        else
                # Rebuild disk block
                sgdisk -e /dev/$disk
                partprobe

                # Increase partition capacity
                parted /dev/$disk resizepart $partition 100%

                # Check FileSystem TYPE XFS or EXT4
                fs_type=`blkid -o value -s TYPE $fs`
                if [ $fs_type == "xfs" ]; then
                        xfs_growfs $fs
                else
                        resize2fs $fs
                fi
        fi
else
        echo "Cannot process partition ${disk}${partition} because this partition does not exist or not the last partition."
fi
