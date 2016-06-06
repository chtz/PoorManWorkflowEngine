#/bin/bash
SCRIPT_ID=`cat wf_start.cloud.id`
WF_FILE=$1
ruby wf_start_data.rb $WF_FILE | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID | ruby wf_command_filter.rb $WF_FILE 
