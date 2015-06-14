#!/bin/zsh

# Don't allow multiple copies to run.
if [ $(pidof -x $(basename $0) | wc -w) -gt 2 ]; then
  exit 0
fi

FONT="-*-terminus-*-r-normal-*-14-*-*-*-*-*-*-*"
CRIT="#acc267"

XRES=1920
WIDTH=$((14*13))
PANELHEIGHT=20

TODAY=$(expr `date +'%d'` + 0)
MONTH=$(date +'%m')
YEAR=$(date +'%Y')

(
echo '^bg(#303030)^fg(#b0b0b0)'
echo '       ^fg(#f5f5f5)CALENDAR'

# Current month, with header and current day highlighted.
cal | sed -r -e "1,2 s/.*/^fg(#b0b0b0)&^fg()/" -e "s/(^| )($TODAY)($| )/\1^bg()^fg($CRIT)\2^fg()^bg()\3/" -e "s/^/ /"

# Next month, with header highlighted.
[ $MONTH -eq 12 ] && YEAR=`expr $YEAR + 1`
cal `expr \( $MONTH + 1 \) % 12` $YEAR | sed -e "1,2 s/.*/^fg(#b0b0b0)&^fg()/" -e "s/^/ /"
) \
| dzen2 -p 60 -fn "$FONT" -x $((XRES-WIDTH-1)) -y $((PANELHEIGHT+1)) -w $WIDTH -l 18 -sa l -e 'onstart=uncollapse;button3=exit'
