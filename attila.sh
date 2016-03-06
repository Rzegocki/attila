#! /bin/bash
server="$(cat config/server)"
key="$(cat config/key)"
key2="$(cat config/key2)"
mkdir ipinfo



ip="131.252.211"

function alive {
    for i in {194..222};do
       if `ping -W 1 -c 1 ${ip}.${i} > /dev/null`; then
        send "PRIVMSG $1 :${ip}.${i}" 
        sleep 1 
       fi
    done
    send "PRIVMSG $1 :Done"
}

function free {
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

function ipuser {
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
#        send "JOIN #catacombs $key"
        started="yes"
    fi

    read irc
    echo "<- $irc"

#reply to server ping
    if $(echo $irc | cut -d ' ' -f 1 | grep 'PING' > /dev/null); then
        send 'PONG'
    fi




    if `echo $irc | cut -d ' ' -f 2 | grep PRIVMSG > /dev/null`; then
        nick="`echo $irc | cut -d '!' -f1`"
        chan="`echo $irc | cut -d ' ' -f3`"
        message="`echo $irc | tr -d "\r\n" | cut -d ' ' -f4- | cut -c 2-`"
        if `echo $message| egrep '^attila:\s+\S+\s+is\s' > /dev/null`; then
            ipuser "$chan" "$message"
        elif `echo "$message"| cut -c 1 | grep '?' > /dev/null`; then
            if `echo "$message" | cut -c 2- | egrep '^free ips$' > /dev/null`;then
                free "$chan"
            elif `echo "$message" | cut -c 2- | egrep '^who is alive$' > /dev/null`;then
                alive "$chan"
            elif `echo "$message" | cut -c 2- | egrep '^help$' > /dev/null`;then
                send "PRIVMSG $chan :You asked who is help."  

            fi
        fi
    fi


#if the message is directed to the bot name




done
