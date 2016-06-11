#/bin/bash
SCRIPT_ID=`cat wf_start.cloud.id`
WF_FILE=$1
DEF_ID=$2
INST_ID=$3
ruby wf_start_data.rb $WF_FILE $DEF_ID $INST_ID | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID | ruby wf_command_filter.rb $WF_FILE 
