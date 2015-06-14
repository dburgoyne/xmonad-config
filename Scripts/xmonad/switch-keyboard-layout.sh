#!/bin/zsh

if [[ -n "$1" ]]; then
    setxkbmap $1
else
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    case $layout in
		us)
			setxkbmap ca fr
			;;
		ca)
			setxkbmap de qwerty
			;;
		de)
			setxkbmap pl
			;; 
		*)
			setxkbmap us altgr-intl
			;;
    esac
fi
