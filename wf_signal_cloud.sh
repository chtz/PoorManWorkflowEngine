#/bin/bash
SCRIPT_ID=`cat wf_signal.cloud.id`
WF_FILE=$1
ruby wf_signal_data.rb $WF_FILE | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID
