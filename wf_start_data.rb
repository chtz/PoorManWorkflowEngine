require "json"

start_input_json = {
  "definition" => File.read(ARGV[0]),
  "state" => {}
}.to_json

puts start_input_json
