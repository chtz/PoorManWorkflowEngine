#!/bin/bash
ruby wf_start_data.rb test3_wf.rb | ruby wf_start.rb | json_pp > state.json
cat state.json
cat state.json | ruby wf_signal_data.rb test3_wf.rb | ruby wf_signal.rb | json_pp > state2.json
cat state2.json
cat state2.json | ruby wf_signal_data.rb test3_wf.rb | ruby wf_signal.rb | json_pp > state3.json
cat state3.json
