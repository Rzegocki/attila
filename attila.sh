#! /bin/bash
server="$(cat config/server)"
key="$(cat config/key)"
key2="$(cat config/key2)"
ip="$(cat config/ip)"
helpfile="$(cat config/helps)"
mkdir ipinfo



function alive { # will print stdout if responds to ping
    for i in {194..222} {226..238};do
       if `ping -W 1 -c 1 ${ip}.${i} > /dev/null`; then
          if [ -e "ipinfo/${i}" ]; then
               content="`cat ipinfo/${i}`"
            fi
           send "PRIVMSG $1 :${ip}.${i} $content"
           content="" 
        sleep 1 
       fi
    done
    send "PRIVMSG $1 :Done"
}

function free { # this will print stdout when ip does not respond to ping
    for i in {194..222};do
       if ! `ping -W 1 -c 1 ${ip}.${i} > /dev/null`; then
            if [ -e "ipinfo/${i}" ]; then
               content="`cat ipinfo/${i}`"
            fi
           send "PRIVMSG $1 :${ip}.${i} $content"
           content="" 
       fi
    done
    send "PRIVMSG $1 :Done"
}

function helps {
saveIFS=$IFS
IFS=$'\n'
for i in $(echo "$helpfile"); do
    send "PRIVMSG $1 :$i"
    sleep 1   
done
IFS=$saveIFS
}


function ipuser { #assigns username to ip
    filename="`echo "$2" | cut -d ' ' -f2 `"
    username="`echo "$2" | cut -d ' ' -f4- `"
        if `echo "$filename" | egrep '[0-9][0-9][0-9]' > /dev/null`; then
            if [ -z "$username" ]; then
                rm ipinfo/$filename
            else
            echo "$username" > ipinfo/$filename    
            fi
            send "PRIVMSG $1 :success"
        fi        
}
#function that deletes unused ip addresses
function forget {
    forgetme="`echo "$message" | cut -d ' ' -f3 `"    
            rm ipinfo/$forgetme
    send "PRIVMSG $chan :success"
}

# function that sends its first arg to the irc server
function send {
echo "-> $1"
echo "$1" >> .botfile
}

rm .botfile 2> /dev/null
mkfifo .botfile
# connect to the irc server
tail -f .botfile | openssl s_client -connect $server:6697 | while true; do
    if [[ -z $started ]] ; then
        # join irc channels
        send "USER attila attila attila :attila"
        send "NICK attila"
        send "JOIN #bloctest $key2"
        send "JOIN #catacombs $key"
        started="yes"
    fi

    read irc
    echo "<- $irc"

#reply to server ping
    if $(echo $irc | cut -d ' ' -f 1 | grep 'PING' > /dev/null); then
        send 'PONG'
    fi

#listen to user input and react accordinly
    if `echo $irc | cut -d ' ' -f 2 | grep PRIVMSG > /dev/null`; then
        nick="`echo $irc | cut -d '!' -f1`"
        chan="`echo $irc | cut -d ' ' -f3`"
        message="`echo $irc | tr -d "\r\n" | cut -d ' ' -f4- | cut -c 2-`"
        if `echo $message| egrep '^attila:\s+\S+\s+is\s' > /dev/null`;then
            ipuser "$chan" "$message"
        elif `echo "$message" | egrep '^attila: forget\s+[0-9][0-9][0-9]$' > /dev/null`;then
            forget $chan
        elif `echo "$message"| cut -c 1 | grep '?' > /dev/null`; then
            if `echo "$message" | cut -c 2- | egrep '^free ips$' > /dev/null`;then
                free "$chan"
            elif `echo "$message" | cut -c 2- | egrep '^who is alive$' > /dev/null`;then
                alive "$chan"
            elif `echo "$message" | cut -c 2- | egrep '^help$' > /dev/null`;then
                helps "$chan"
            elif `echo "$message" | cut -c 2- | egrep '^source$' > /dev/null`;then
                send "PRIVMSG $chan :https://github.com/Rzegocki/attila.git"  
            fi
        fi
    fi
done
