#!/bin/bash
echo '{}' | ./wf_start_cloud.sh test4_wf.rb | ./wf_signal_cloud.sh test4_wf.rb | json_pp

