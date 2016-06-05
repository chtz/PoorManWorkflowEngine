#/bin/bash
echo '{"foo":"bar"}' | ./wf_start_cloud.sh test3_wf.rb  | ./wf_signal_cloud.sh test3_wf.rb > state.json

echo '~~~<666~END~OF~SCRIPT~999>~~~
{"bar":"foo"}' >> state.json 

cat state.json | ./wf_signal_cloud.sh test3_wf.rb | json_pp
