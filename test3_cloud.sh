#/bin/bash
./wf_start_cloud.sh test3_wf.rb  | ./wf_signal_cloud.sh test3_wf.rb | ./wf_signal_cloud.sh test3_wf.rb | json_pp