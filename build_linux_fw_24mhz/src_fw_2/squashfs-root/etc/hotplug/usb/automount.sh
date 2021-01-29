#! /bin/sh

if [ "$1" == "" ]; then
	echo "parameter is none."
	exit 1
fi

mounted=`mount | grep -w $1 | wc -l`
# mounted, assume we umount

if [ $mounted -eq 1 ]; then
    echo -e "\033[1;31m[AUTOMOUNT] udpsend remove $1 action\033[0m" > /dev/ttyS0
	udpsend remove $1 > /dev/null
	while true
	do
		/bin/umount "/media/$1" 2>>/dev/null
		sync
        mounted=`mount | grep -w $1 | wc -l`
		if [ $mounted -eq 0 ]; then
			break
		fi
        echo -e "\033[1;31m[AUTOMOUNT] Try to umount /media/$1 again\033[0m" > /dev/ttyS0
        /bin/umount -l "/media/$1" 2>>/dev/null
        sync
	done
	if ! rmdir "/media/$1"; then
		exit 1
	fi
	# not mounted, lets mount under /media
else
	if [[ `expr length $1` -eq 3 ]] && [[ `ls /dev/$1? | wc -l` -gt 0 ]]; then
		exit 1
	fi
	if [ `expr length $1` -eq 3 ]; then
		sleep 1
		if [[ `expr length $1` -eq 3 ]] && [[ `ls /dev/$1? | wc -l` -gt 0 ]]; then
			exit 1
		fi
	fi
	FSTYPE=`blkid /dev/$1 | sed "s/.*TYPE=\"\(.*\)\"/\1/"`
	if [ "$FSTYPE" == "" ]; then
		exit 1
	fi

	if ! mkdir -p "/media/$1"; then
		exit 1
	fi

	if [ "$FSTYPE" == "ntfs" ]; then
        FS=`cat /proc/filesystems | grep gntfs | awk '{print $1}'`
        echo -e "\033[1;32m[AUTOMOUNT] Mount /dev/$1 to /media/$1 ($FS) \033[0m" > /dev/ttyS0
		if [ "$FS" == "gntfs"  ]; then
			mount -t gntfs "/dev/$1" "/media/$1" 2> /dev/null
		else
			ntfs-3g "/dev/$1" "/media/$1" 2> /dev/null
		fi
	fi
	if [ "$FSTYPE" == "vfat" ];then
        FS=`cat /proc/filesystems | grep vfat | awk '{print $1}'`
        echo -e "\033[1;32m[AUTOMOUNT] Mount /dev/$1 to /media/$1 ($FS) \033[0m" > /dev/ttyS0
		if [ "$FS" == "vfat" ];then
			mount -t vfat -o shortname=mixed "/dev/$1" "/media/$1" 2> /dev/null
		fi
	else
		mount "/dev/$1" "/media/$1" 2> /dev/null
	fi

	if [ ! $? ]; then
		# failed to mount, clean up mountpoint
		rmdir "/media/$1"
		exit 1
	else
        echo -e "\033[1;32m[AUTOMOUNT] udpsend add $1 action\033[0m" > /dev/ttyS0
		udpsend add $1 > /dev/null
	fi

	# Run external application scripts
	if test -d /media/sda1/etc/rcS.d/; then
		for RCS in /media/sda1/etc/rcS.d/S*; do
			if test -r "$RCS"; then
				. "$RCS" start
			fi
		done
		unset RCS
	fi

fi

exit 0
