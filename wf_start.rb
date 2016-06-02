require "./rbpm10.rb"

start_input_json = ""
while line = gets
  start_input_json = start_input_json + line
end

start_input = JSON.parse(start_input_json)

eval(start_input["definition"])

instance = @definition.create
instance.token.variables = start_input["variables"] if start_input["variables"]

instance.token.signal

puts instance.to_hash.to_json
