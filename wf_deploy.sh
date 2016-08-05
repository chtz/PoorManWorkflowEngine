#/bin/bash

cat rbpm10.rb > wf_start.local
tail -n +2 wf_start.rb >> wf_start.local

SCRIPT_ID=`curl -s --header "Content-Type:text/plain" --data-binary @wf_start.local http://localhost:8080/`
echo $SCRIPT_ID > wf_start.local.id

cat rbpm10.rb > wf_signal.local
tail -n +2 wf_signal.rb >> wf_signal.local

SCRIPT_ID=`curl -s --header "Content-Type:text/plain" --data-binary @wf_signal.local http://localhost:8080/`
echo $SCRIPT_ID > wf_signal.local.id
