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

#http_post 'https://letsencrypt.up4sure.ch/up4sureSignup', 'application/json', '{"externalServerId":"ff825094-c5cf-4d2b-909a-2a06861f48f8","url":"http://www.tschenett.ch","email":"alert@tschenett.ch"}', { 'x-api-key' => 'ky6bg0mCmz8Vxe6cRiMqs7jv1MLWjGEJ7olKgLRq' }
def http_post(uri, content_type, data, headers = nil)
  uri = URI(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  headers = {} unless headers
  headers['Content-Type'] = content_type
  request = Net::HTTP::Post.new(uri.request_uri, initheader = headers)
  request.body = data
  response = http.request(request)
  response.body
end

#apply_template "Hallo {{name}}, wie geht's denn {{ref}} so?", {"name"=>"willi","ref"=>"dir"}
def apply_template(s, h)
  h.each do |k,v|
    if s.index("{{#{k.to_s}}}")
      s = s.gsub("{{#{k.to_s}}}", v.to_s)
    end
  end
  s
end

command_token = find_first_command_token(state["token"])

if command_token
  command = command_token["variables"]["command"]
  if command && command.kind_of?(Array)
    if command[0] == "http_get" 
      command_token["variables"]["result"] = http_get(apply_template(command[1], command_token["variables"]))
    elsif command[0] == "http_post"
      command_token["variables"]["result"] = http_post(apply_template(command[1], command_token["variables"]), 
        command[2], 
        apply_template(command[3], command_token["variables"]), 
        command[4]) 
    elsif command[0] == "sleep"
      puts state.to_json
      return  
    end

    command_token["variables"].delete "command"
  end
  
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