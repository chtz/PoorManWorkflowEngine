#/bin/bash
SCRIPT_ID=`cat wf_signal.local.id`
WF_FILE=$1
ruby wf_signal_data.rb $WF_FILE | curl -s --header "Content-Type:text/plain" -d @- http://localhost:8080/$SCRIPT_ID | ruby wf_command_filter.rb $WF_FILE
