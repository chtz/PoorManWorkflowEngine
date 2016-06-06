#{
#   "token" : {
#      "variables" : {
#         "command" : [
#            "HTTPGET",
#            "www.tschenett.ch"
#         ]
#      },
#      "childs" : [],
#      "node" : "state_a",
#      "uuid" : "584a115e-26ac-412e-b466-e0853527b088"
#   }
#}

require 'json'
require 'open3'
require 'stringio'
require 'net/http'

state = JSON.parse(STDIN.read)

def find_first_command_token(token)
  if token["variables"]["command"]
    return token
  elsif !token["childs"].empty?
    token["childs"].each do |child|
      match = find_first_command_token(child)
      return match if match
    end
    return nil
  else
    return nil
  end
end

def http_get(uri)
  Net::HTTP.get(URI(uri))
end

command_token = find_first_command_token(state["token"])

if command_token
  command_token["variables"]["result"] = http_get(command_token["variables"]["command"][1])
  command_token["variables"].delete "command"
  
  Open3.popen3("./wf_signal_cloud.sh #{ARGV[0]}") do |stdin, stdout, stderr|
    stdin.puts state.to_json
    stdin.puts "~~~<666~END~OF~SCRIPT~999>~~~"
    stdin.puts "{}"
    stdin.puts "~~~<666~END~OF~SCRIPT~999>~~~"
    stdin.puts command_token["uuid"]
    stdin.close
    IO.copy_stream(stdout, STDOUT)
  end
else
  puts state.to_json
end