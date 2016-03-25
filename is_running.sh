#!/bin/bash

if  pidof -x "attila.sh">/dev/null
	then
	exit 0
else 
	cd $(dirname $0)
	tmux new -d -s attilabot ./attila.sh  
fi
