require "json"

state_input_json = ""
while line = STDIN.gets
  state_input_json = state_input_json + line
end

state_input = JSON.parse(state_input_json)

signal_input_json = {
  "definition" => File.read(ARGV[0]),
  "state" => state_input
}.to_json

puts signal_input_json
