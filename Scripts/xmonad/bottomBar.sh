#!/bin/zsh
# Depends: dzen2 && conky

while test $# -gt 0; do
	case "$1" in
		-xres)
			shift
			if test $# -gt 0; then
				export XRES=$1
			else
				exit 1
			fi
			shift
			;;
		-yres)
			shift
			if test $# -gt 0; then
				export YRES=$1
			else
				exit 1
			fi
			shift
			;;
		-xoffset)
			shift
			if test $# -gt 0; then
				export XOFFSET=$1
			else
				exit 1
			fi
			shift
			;;
		-yoffset)
			shift
			if test $# -gt 0; then
				export YOFFSET=$1
			else
				exit 1
			fi
			shift
			;;
		-boxheight)
			shift
			if test $# -gt 0; then
				export PANELBOXHEIGHT=$1
			else
				exit 1
			fi
			shift
			;;
		-height)
			shift
			if test $# -gt 0; then
				export HEIGHT=$1
			else
				exit 1
			fi
			shift
			;;
		-width)
			shift
			if test $# -gt 0; then
				export WIDTH=$1
			else
				exit 1
			fi
			shift
			;;
		*)
			break
			;;
	esac
done

# Colours, fonts and paths.
CRIT="#acc267" #green
CRIT2="#fb9fb1" #red
BAR_FG="#6fc2ef" #blue
BAR_BG="#151515"
DZEN_FG="#b0b0b0"
DZEN_FG2="#f5f5f5"
DZEN_BG="#303030"
DZEN_BG2="#151515"
FONT="-*-terminus-*-r-normal-*-14-*-*-*-*-*-*-*"
LEFTBOXICON="/home/dburgoyne/Scripts/xmonad/boxleft16.xbm"
RIGHTBOXICON="/home/dburgoyne/Scripts/xmonad/boxright16.xbm"
CONKYFILE="/home/dburgoyne/Scripts/xmonad/conkyXmonad"

# Default values.
IFS='|'
INTERVAL=2.0
CPUTemp=0
GPUTemp=0
CPULoad0=0
CPULoad1=0
CPULoad2=0
CPULoad3=0
CPULoad4=0
CPULoad5=0
CPULoad6=0
CPULoad7=0
X_POS_L=0
Y_POS=0

#==========================================
#FUNCTIONS
#==========================================

textBox() {
	echo -n "^fg("$3")^i("$LEFTBOXICON")^ib(1)^r("$XRES"x"$PANELBOXHEIGHT")^p(-"$XRES")^fg("$2")"$1"^fg("$3")^i("$RIGHTBOXICON")^fg("$4")^r("$XRES"x"$PANELBOXHEIGHT")^p(-"$XRES")^fg()^ib(0)"
}

printKbdInfo() {
	local layout=$(setxkbmap -query | grep layout | awk '{print $2}')
	local variant=$(setxkbmap -query | grep variant | awk '{print $2}')
	
	local LABEL=$(textBox "KEYBOARD" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})

	if [[ $variant == "" ]]; then
		local VALUE=$(textBox "^fg($BAR_FG)${layout}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	else
		local VALUE=$(textBox "^fg($BAR_FG)${layout}:${variant}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	fi
	
	echo -n ${LABEL}${VALUE}
	
	return
}

printVolInfo() {
	local Perc=$(amixer get Master | grep "Front Left:" | awk '{print $5}' | tr -d '[]%')
	local Mute=$(amixer get Master | grep "Front Left:" | awk '{print $6}' | tr -d '[]%')
	if [[ $Mute == "off" ]]; then
		textBox "^ca(1,$VOL_TOGGLE_CMD)^ca(4,$VOL_UP_CMD)^ca(5,$VOL_DOWN_CMD)VOLUME ^fg(${CRIT2})${Perc}%^ca()^ca()^ca()" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG}
	else
		textBox "^ca(1,$VOL_TOGGLE_CMD)^ca(4,$VOL_UP_CMD)^ca(5,$VOL_DOWN_CMD)VOLUME ^fg(${CRIT})${Perc}%^ca()^ca()^ca()" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG}
	fi
	return
}

printCPUInfo() {
	[[ $CPULoad0 -gt 70 ]] && CPULoad0="^fg($CRIT)$CPULoad0^fg()"
	[[ $CPULoad1 -gt 70 ]] && CPULoad1="^fg($CRIT)$CPULoad1^fg()"
	[[ $CPULoad2 -gt 70 ]] && CPULoad2="^fg($CRIT)$CPULoad2^fg()"
	[[ $CPULoad3 -gt 70 ]] && CPULoad3="^fg($CRIT)$CPULoad3^fg()"
	[[ $CPULoad4 -gt 70 ]] && CPULoad4="^fg($CRIT)$CPULoad4^fg()"
	[[ $CPULoad5 -gt 70 ]] && CPULoad5="^fg($CRIT)$CPULoad5^fg()"
	[[ $CPULoad6 -gt 70 ]] && CPULoad6="^fg($CRIT)$CPULoad6^fg()"
	[[ $CPULoad7 -gt 70 ]] && CPULoad7="^fg($CRIT)$CPULoad7^fg()"
	local VALUE=$(textBox "^fg($BAR_FG)${CPULoad0}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad1}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad2}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad3}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad4}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad5}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad6}%^fg($DZEN_FG2)/^fg($BAR_FG)${CPULoad7}%" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local LABEL=$(textBox "CPU" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	echo -n ${LABEL}${VALUE}
	return
}

printTempInfo() {
	local sensordata=`sensors`
	local CPUTemp0=$(echo $sensordata | grep "Core 0:" | awk '{print substr($3,0,7)}')
	local CPUTemp1=$(echo $sensordata | grep "Core 1:" | awk '{print substr($3,0,7)}')
	local CPUTemp2=$(echo $sensordata | grep "Core 2:" | awk '{print substr($3,0,7)}')
	local CPUTemp3=$(echo $sensordata | grep "Core 3:" | awk '{print substr($3,0,7)}')
	
	local CPUTemp0num=$(echo $CPUTemp0 | awk '{print substr($0,2,2)}')
	local CPUTemp1num=$(echo $CPUTemp1 | awk '{print substr($0,2,2)}')
	local CPUTemp2num=$(echo $CPUTemp2 | awk '{print substr($0,2,2)}')
	local CPUTemp3num=$(echo $CPUTemp3 | awk '{print substr($0,2,2)}')
	
	[[ $CPUTemp0num -gt 70 ]] && CPUTemp0="^fg($CRIT)$CPUTemp0^fg()"
	[[ $CPUTemp1num -gt 70 ]] && CPUTemp1="^fg($CRIT)$CPUTemp1^fg()"
	[[ $CPUTemp2num -gt 70 ]] && CPUTemp2="^fg($CRIT)$CPUTemp2^fg()"
	[[ $CPUTemp3num -gt 70 ]] && CPUTemp3="^fg($CRIT)$CPUTemp3^fg()"
	local VALUE=$(textBox "^fg($BAR_FG)${CPUTemp0}^fg($DZEN_FG2)/^fg($BAR_FG)${CPUTemp1}^fg($DZEN_FG2)/^fg($BAR_FG)${CPUTemp2}^fg($DZEN_FG2)/^fg($BAR_FG)${CPUTemp3}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local LABEL=$(textBox "TEMP" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	echo -n ${LABEL}${VALUE}
	return
}

printMemInfo() {
	[[ $MemPerc -gt 70 ]] && MemTemp="^fg($CRIT)$MemPerc^fg()"
	local VALUE=$(textBox "^fg($BAR_FG)${MemPerc}%^fg($DZEN_FG2)/^fg($BAR_FG)${MemUsed}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local LABEL=$(textBox "RAM" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	echo -n ${LABEL}${VALUE}
	return
}

printBatteryInfo() {

	local rawstatus=`/usr/bin/cat /sys/class/power_supply/BAT0/status`
	local batstatus="Unknown"
	if [ $rawstatus '==' "Unknown" ]; then batstatus="Connected"; fi
	if [ $rawstatus '==' "Full" ]; then batstatus="Full"; fi
	if [ $rawstatus '==' "Discharging" ]; then batstatus="Discharging"; fi
	if [ $rawstatus '==' "Charging" ]; then batstatus="Charging"; fi
	local BATStatus=$([ -f /sys/class/power_supply/BAT0/status ] && echo ${batstatus} || echo 'Connected')
	local BATCap=$([ -f /sys/class/power_supply/BAT0/capacity ] && echo $(/usr/bin/cat /sys/class/power_supply/BAT0/capacity)"%" || echo 'N/A')
	local VALUEC=$(textBox "^fg($CRIT)${BATStatus}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local VALUE=$(textBox "^fg($BAR_FG)${BATCap}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local LABEL=$(textBox "BATTERY" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	echo -n ${LABEL}${VALUE}${VALUEC}
}

printWifiInfo() {
	local WIFISignal="N/A"
	if [[ $(/usr/sbin/iwconfig wlp3s0 | grep -c 'ESSID:off/any') == "0" ]]; then
		WIFISignal=$(/usr/sbin/iwconfig wlp3s0 | awk -F '=' '/Quality/ {print $2}' | cut -d '/' -f 1)"%"
	fi
	local VALUE=$(textBox "^fg($BAR_FG)${WIFISignal}" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	local LABEL=$(textBox "WIFI" ${DZEN_FG2} ${DZEN_BG2} ${DZEN_BG})
	echo -n ${LABEL}${VALUE}${VALUEC}
}

printRight() {
    while true; do
	read CPULoad0 CPULoad1 CPULoad2 CPULoad3 CPULoad4 CPULoad5 CPULoad6 CPULoad7 CPUFreq MemUsed MemPerc
	printKbdInfo
	echo -n " "
    printVolInfo
	echo -n " "
	printCPUInfo
	echo -n " "
	printMemInfo
	echo -n " "
	printTempInfo
	echo -n " "
	printWifiInfo
	echo -n " "
	printBatteryInfo
	echo
    done
    return
}

#==========================================
# MAIN
#==========================================

# Print everything and pipe it into dzen2.
conky -c $CONKYFILE -u $INTERVAL | printRight | dzen2 -x $((XOFFSET+XRES-WIDTH)) -y $((YOFFSET+YRES)) -w $WIDTH -h $HEIGHT -fn $FONT -ta 'r' -bg $DZEN_BG -fg $DZEN_FG -p -e 'onstart=lower'
