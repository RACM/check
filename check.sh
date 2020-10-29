#!/bin/bash
#
#Intelsat IDFM check script
#
#Ruben Calzadilla, Tyler Moeller and Robert Read
#
#v1.1  October 2020
#Only iperf enabled, not iperf3
#

clear

txtrst=$(tput sgr0)
txtred=$(tput setaf 1)
txtgrn=$(tput setaf 2)
txtblu=$(tput setaf 4)

DIR="/dvp100/confd"

mode=$1

echo "${txtblu} ___ ____  _____ __  __"
echo "|_ _|  _ \|  ___|  \/  |"
echo " | || | | | |_  | |\/| |"
echo " | || |_| |  _| | |  | |"
echo "|___|____/|_|   |_|  |_| ${txtrst}"

IPM=`ip a | grep eth7 | grep inet | awk '{print$2}' | cut -d \/ -f 1 | head -1`
NIP=`ip a | grep eth7 | grep inet | awk '{print$2}' | cut -d \/ -f 1 | wc -l | awk '{print$1*1}'`
if [[ $NIP -eq 2 ]]; then
	echo " "
	echo "MASTER: ${IPM}"
fi
if [[ $NIP -eq 1 ]]; then
	echo " "
	echo "SLAVE: ${IPM}"
fi

if [[ -z $mode ]]; then
	echo " "
	echo " Which mode? 0 = check Internet connection" 
	echo "             1 = check UDP bandwidth: California"
	echo "             2 = check UDP bandwidth: Virginia"
	echo " "
	echo " Example: #check 1"
	echo " "
	exit 1
fi

mode=$(echo $mode | awk '{print$1*1}')


iperf -v > /dev/null 2>&1
if [[ $? -ne 1 ]]; then
    echo " "
    echo "${txtred}The application [ iperf ] is not installed or the path to it is not set in the PATH variable, exiting...${txtrst}"
    echo " "
    exit 1
fi

if [[ $mode -eq 0 ]]; then
	echo " "
	echo "** Checking Internet Connection **"
	timeout 3 ping -I eth0.2998 -c3 8.8.8.8 > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo " "
		echo "${txtred}No Internet Connection, Please check!${txtrst}"
		echo " "
		exit 1
	else
		echo " "
		echo "${txtgrn}The System is Connected to the Internet!${txtrst}"
		echo " "
	fi
fi

if [[ $mode -eq 1 ]]; then

    echo " "
    echo "How much bandwidth to check for? [1 - 10] Mbps: "
    read udpbw

	echo " "
	echo "** Checking UDP Throughput for ${udpbw}Mbps **"
#	echo "   Runing UDP Bandwidth check for = ${udpbw} Mbps"

	timeout 3 ping -I eth0.2998 -c1 8.8.8.8 > /dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo " "
		echo "${txtred}No Internet Connection, Please check!${txtrst}"
		echo " "
		exit 1
	fi

	IP=`ip a | grep eth0.2998 | grep inet | awk '{print$2}' | cut -d \/ -f 1`

	timeout 10 iperf -B ${IP} -c ${cIP} -p 5100 -t 5 -u -b ${udpbw}M 2>/dev/null > /tmp/udpUp
#	sleep 2
#	timeout 10 iperf -B ${IP} -c 18.144.83.129 -p 5100 -t 5 -u -b ${udpbw}M -R > /tmp/udpDown

    UDPUP=`cat /tmp/udpUp | grep "Mbits" | awk '{print$8}'`
#	UDPUP=`cat /tmp/udpUp | grep "sender" | awk '{print$7,$8}'`
#	LOSSU=`cat /tmp/udpUp | grep "receiver" | awk '{print$12}'`
#	LOSSU=$(echo $LOSSU | sed "s/(//g; s/)//g")
#	lossu=$(echo $LOSSU | sed "s/(//g; s/)//g; s/%//g")
#	lossu=$(echo $lossu | awk '{print$1*1}')
#	lossuc=$(ueil $lossu)
#	if [[ $lossuc -gt 1 ]]; then
#		coloru=$(tput setaf 1)
#	else
#		coloru=$(tput setaf 2)
#	fi
#
#	UDPDOWN=`cat /tmp/udpDown | grep "sender" | awk '{print$7,$8}'`
#	LOSSD=`cat /tmp/udpDown | grep "receiver" | awk '{print$12}'`
#	LOSSD=$(echo $LOSSD | sed "s/(//g; s/)//g")
#	lossd=$(echo $LOSSD | sed "s/(//g; s/)//g; s/%//g")
#	lossd=$(echo $lossd | awk '{print$1*1}')
#	lossdc=$(ueil $lossd)
#	if [[ $lossdc -gt 1 ]]; then
#		colord=$(tput setaf 1)
#	else
#		colord=$(tput setaf 2)
#	fi

	echo " "
	echo "UDP Upload = [${txtgrn} $UDPUP ${txtrst}] Mbps"
#	echo "UDP Upload   = [${txtgrn} $UDPUP ${txtrst}] - Lost Datagrams [${coloru} ${LOSSU} ${txtrst}]"
#	echo "UDP Download = [${txtgrn} $UDPDOWN ${txtrst}] - Lost Datagrams [${colord} ${LOSSD} ${txtrst}]"
fi

echo " "
echo "${txtblu}Script is done${txtrst}"
echo " "
echo " "
exit 0
