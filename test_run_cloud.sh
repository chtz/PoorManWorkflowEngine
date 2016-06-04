#/bin/bash
SCRIPT_ID=`cat wf_start.cloud.id`

ruby wf_start_data.rb | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID | json_pp > state.json

SCRIPT_ID=`cat wf_signal.cloud.id`

cat state.json | ruby wf_signal_data.rb | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID | json_pp > state2.json

cat state2.json | ruby wf_signal_data.rb | curl -s --header "Content-Type:text/plain" -d @- http://www.sandbox.p.iraten.ch/$SCRIPT_ID | json_pp
