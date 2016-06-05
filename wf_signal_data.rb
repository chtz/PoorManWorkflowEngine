require "json"

stage = 0
state_input_json = ""
variables_input_json = ""
token = nil
while line = STDIN.gets
  if line =~ /~~~<666~END~OF~SCRIPT~999>~~~.*/
    stage = stage + 1
  else  
    if stage == 0
      state_input_json = state_input_json + line
    elsif stage == 1
      variables_input_json = variables_input_json + line
    else
      token = line.chomp
    end
  end
end

state_input = JSON.parse(state_input_json)
variables_input = JSON.parse(variables_input_json) unless variables_input_json.empty? || variables_input_json.chomp.empty?

signal_input = {
  "definition" => File.read(ARGV[0]),
  "state" => state_input,
  "variables" => variables_input,
}

signal_input["token"] = token if token

signal_input_json = signal_input.to_json

puts signal_input_json
