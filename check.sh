#!/bin/bash
#
#Intelsat IDFM check script
#
#Ruben Calzadilla, Tyler Moeller and Robert Read
#
#v1.5  November 2020
#Only iperf enabled, not iperf3
#added server in Virginia and check for routing issues
#

clear

#Available iperf servers
SIPA[1]="18.144.83.129,California"
SIPA[2]="54.84.2.228,Virginia"

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
	echo "MASTER's IP: ${IPM}"
fi
if [[ $NIP -eq 1 ]]; then
	echo " "
	echo "You are Logged in the SLAVE: ${IPM}"
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

checkInternet () {
	echo " "
	if [[ $mode -eq 0 ]]; then
	    echo "** Checking Internet Connection **"
	else
		echo "** Verifying Internet Connection first **"
	fi

	#timeout 3 ping -b en0 -c3 8.8.8.8 > /dev/null 2>&1
	timeout 3 ping -I eth0.2998 -c3 8.8.8.8 > /dev/null 2>&1

	if [[ $? -ne 0 ]]; then
		echo " "
		echo "${txtred}No Internet Connection, Please check!${txtrst}"
		echo " "
		exit 1
	else
		timeout 3 ping -c3 8.8.8.8 > /dev/null 2>&1
		if [[ $? -eq 0 ]]; then
		    echo " "
		    echo "${txtgrn}The System is Connected to the Internet${txtrst}"
		    echo " "
		else
			echo " "
		    echo "${txtred}The System is Connected to the Internet, but there is a routing issue."
		    echo "Please check the routing table!${txtrst}"
		    echo " "
		    exit 1
		fi
	fi
}

checkBW () {
	iperf -v > /dev/null 2>&1
    if [[ $? -ne 1 ]]; then
	    echo " "
	    echo "${txtred}The application [ iperf ] is not installed or the path to it is not set in the PATH variable, exiting...${txtrst}"
	    echo " "
	    exit 1
	fi

    SIP=$(echo ${SIPA[$mode]} | cut -d, -f1)
    SIPL=$(echo ${SIPA[$mode]} | cut -d, -f2)

    echo "How much bandwidth to check for? [1 - 50] Mbps: "
    read udpbw

	echo " "
	echo "** Checking UDP Throughput for ${udpbw}Mbps with server in ${SIPL} **"

	timeout 10 iperf -c ${SIP} -p 5100 -t 5 -u -b ${udpbw}M 2>/dev/null > /tmp/udpUp

    UDPUP=`cat /tmp/udpUp | grep "Mbits" | awk '{print$8}'`

	echo " "
	echo "UDP Upload = [${txtgrn} $UDPUP ${txtrst}] Mbps to ${SIPL}"
	echo " "
}


if [[ $mode -eq 0 ]]; then
	checkInternet
	exit 0
fi

if [[ $mode -eq 1 ]] || [[ $mode -eq 2 ]]; then
	checkInternet
	checkBW
	exit 0
else
	echo " "
	echo "${txtred}Mode [ $mode ] is not a valid mode${txtrst}"
	echo " "
	exit 1
fi

echo " "
echo "${txtblu}Script is done${txtrst}"
echo " "
echo " "
exit 0
