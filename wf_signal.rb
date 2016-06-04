require "./rbpm10.rb"

signal_input_json = ""
while line = gets
  signal_input_json = signal_input_json + line
end

signal_input = JSON.parse(signal_input_json)

eval(signal_input["definition"])

instance = Workflow::Workflow.from_hash(@definition, signal_input["state"])

unless instance.done?
  instance.state_tokens do |token|
    if token["command"] == "RANDOM"
      token["result"] = (rand*1000).to_i
      token.signal
      signal_sent = true
      break
    end
  end
end

puts instance.to_hash.to_json