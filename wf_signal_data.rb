require "json"

expect_state_input = true
state_input_json = ""
variables_input_json = ""
while line = STDIN.gets
  if line =~ /~~~<666~END~OF~SCRIPT~999>~~~.*/
    expect_state_input = ! expect_state_input
  else  
    if expect_state_input
      state_input_json = state_input_json + line
    else
      variables_input_json = variables_input_json + line
    end
  end
end

state_input = JSON.parse(state_input_json)
variables_input = JSON.parse(variables_input_json) unless variables_input_json.empty? || variables_input_json.chomp.empty?

signal_input_json = {
  "definition" => File.read(ARGV[0]),
  "state" => state_input,
  "variables" => variables_input
}.to_json

puts signal_input_json
