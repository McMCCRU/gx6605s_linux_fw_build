#!/bin/sh

device=$1
action=$2

NMASK=""

LOCAL_IP="192.168.30.111"
ROUTE_IP="192.168.30.1"
DNS1="8.8.8.8"
NET_MASK="255.255.255.0"
EN_ETH_PROMISC=""

if [ -f /home/gx/etc/config.conf ]; then
. /home/gx/etc/config.conf
fi

if [ "$action" == "add" ]; then
	echo "Configure network..."

	NEED_UMOUNT=0

	if [ -f /media/sda1/config.conf ]; then
		VALID_CFG=`grep "LOCAL_IP=" /media/sda1/config.conf`
		if [ -n "$VALID_CFG" ]; then
			cp -f /media/sda1/config.conf /home/gx/etc/config.conf
			rm -f /media/sda1/config.conf
			dos2unix /home/gx/etc/config.conf
			NEED_UMOUNT=1
			. /home/gx/etc/config.conf
		fi
	fi

	if [ -f /media/sda1/wpa_supplicant.conf ]; then
		VALID_SUP=`cat /media/sda1/wpa_supplicant.conf | grep "network" | grep "="`
			if [ -n "$VALID_SUP" ]; then
			cp -f /media/sda1/wpa_supplicant.conf /home/gx/etc/wpa_supplicant.conf
			rm -f /media/sda1/wpa_supplicant.conf
			dos2unix /home/gx/etc/wpa_supplicant.conf
			NEED_UMOUNT=1
		fi
	fi

	id_vendor=`cat /sys/bus/usb/devices/$device/idVendor`
	id_product=`cat /sys/bus/usb/devices/$device/idProduct`
	wlan_driver=` grep -i "^$id_vendor:$id_product" /etc/Wireless/wifi_support.conf | cut -d" " -f2`

	if [ -n "$wlan_driver" ] && [ -f /lib/modules/`uname -r`/$wlan_driver ]; then
		insmod /lib/modules/`uname -r`/$wlan_driver 2> /dev/null
		wlan=`ifconfig -a | grep wlan0`
		if [ -n "$wlan" ]; then
			ifconfig wlan0 up 2> /dev/null
			if [ -f /media/sda1/wifi_list.log ]; then
				echo "Stage1:" > /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				iwlist wlan0 scan >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				echo "Stage2:" >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				iwlist wlan0 scan >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				echo "Stage3:" >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				iwlist wlan0 scan >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				echo "Stage4:" >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				iwlist wlan0 scan >> /media/sda1/wifi_list.log
				echo "=======================================================" >> /media/sda1/wifi_list.log
				unix2dos /media/sda1/wifi_list.log
				NEED_UMOUNT=1
			fi
		fi
	else
		ether=`ifconfig -a | grep eth0`
	fi

	if [ $NEED_UMOUNT = 1 ]; then
		umount /media/sda1 2> /dev/null
	fi

	if [ ! -f /home/gx/etc/wpa_supplicant.conf ]; then
		ether=`ifconfig -a | grep eth0`
		wlan=""
	fi

	if [ -n "$wlan" ]; then
		NDEV="wlan0"
	else
		NDEV="eth0"
	fi

	if [ -n "$ether" ] || [ -n "$wlan" ]; then
		echo "nameserver $DNS1" > /etc/resolv.conf

		if [ -n "$DNS2" ]; then
			echo "nameserver $DNS2" >> /etc/resolv.conf
		fi

		if [ -n "$DNS3" ]; then
			echo "nameserver $DNS3" >> /etc/resolv.conf
		fi

		if [ -n "$NET_MASK" ]; then
			NMASK="netmask $NET_MASK"
		fi

		if [ -n "$HW_ADDR" ] && [ -n "$ether" ]; then
			ifconfig eth0 hw ether $HW_ADDR eth0 2> /dev/null
		fi

		ifconfig $NDEV $LOCAL_IP $NMASK up 2> /dev/null
		if [ "$EN_ETH_PROMISC" = "yes" ] && [ -n "$ether" ]; then
			ifconfig eth0 promisc allmulti 2> /dev/null
		fi
		route del default 2> /dev/null
		route add default gw $ROUTE_IP 2> /dev/null
		if [ -n "$wlan" ] && [ -f /home/gx/etc/wpa_supplicant.conf ]; then
			wpa_supplicant -B -D wext -i wlan0 -c /home/gx/etc/wpa_supplicant.conf 2> /dev/null
		fi
	fi
fi

if [ "$action" == "remove" ]; then
	WPA_RUN=`ps | grep wpa_supplicant | grep -v grep`
	if [ -n "$WPA_RUN" ]; then
		killall -15 wpa_supplicant 2> /dev/null
		sleep 1
		rmmod mt7601Usta 2> /dev/null
		rmmod rt5572sta 2> /dev/null
		rmmod rtl8188 2> /dev/null
		rmmod rtl8712u 2> /dev/null
		rmmod rtl8821cu 2> /dev/null
	fi
	echo "Bye!!!"
fi
