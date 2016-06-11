require "json"

state_input_json = ""
while line = STDIN.gets
  state_input_json = state_input_json + line
end

state_input = JSON.parse(state_input_json) unless state_input_json.empty? || state_input_json.chomp.empty?
state_input["definition_uuid"] = ARGV[1]
state_input["instance_uuid"] = ARGV[2]

start_input_json = {
  "definition" => File.read(ARGV[0]),
  "variables" => state_input
}.to_json

puts start_input_json
