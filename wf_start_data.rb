require "json"

start_input_json = {
  "definition" => File.read("test3_wf.rb"),
  "state" => {}
}.to_json

puts start_input_json
