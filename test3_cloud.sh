#/bin/bash
echo '{"foo":"bar"}' | ./wf_start_cloud.sh test3_wf.rb > state1.json

TOKEN1_ID=`cat state1.json | jq -r .token.childs[0].uuid`

echo "~~~<666~END~OF~SCRIPT~999>~~~
{\"result\":900}
~~~<666~END~OF~SCRIPT~999>~~~
$TOKEN1_ID" >> state1.json

cat state1.json  | ./wf_signal_cloud.sh test3_wf.rb > state2.json

TOKEN2_ID=`cat state2.json | jq -r .token.childs[0].uuid`

echo "~~~<666~END~OF~SCRIPT~999>~~~
{\"result\":100}
~~~<666~END~OF~SCRIPT~999>~~~
$TOKEN2_ID" >> state2.json 

cat state2.json | ./wf_signal_cloud.sh test3_wf.rb | json_pp
