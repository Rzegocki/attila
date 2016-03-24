#!/bin/bash

function one() {
if  pidof -x "attila.sh">/dev/null
	then
	exit 0
else 
	tmux new -d -s attilabot /home/attila/bot/attila.sh  
	tmux detach -s attilabot
	exit 0
	
fi
}

#echo "$t1"
#echo "$t0"

#function two() {

#if [ "$t1" -eq 1 ] 
#then	
#	echo "$?"
	
#else 
#	echo "It was a 0"
#fi
#}

one
#two
