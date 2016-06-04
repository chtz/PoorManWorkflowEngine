#/bin/bash

cat rbpm10.rb > wf_start.cloud
tail -n +2 wf_start.rb >> wf_start.cloud

SCRIPT_ID=`curl -s --header "Content-Type:text/plain" --data-binary @wf_start.cloud http://www.sandbox.p.iraten.ch/`
echo $SCRIPT_ID > wf_start.cloud.id

cat rbpm10.rb > wf_signal.cloud
tail -n +2 wf_signal.rb >> wf_signal.cloud

SCRIPT_ID=`curl -s --header "Content-Type:text/plain" --data-binary @wf_signal.cloud http://www.sandbox.p.iraten.ch/`
echo $SCRIPT_ID > wf_signal.cloud.id
