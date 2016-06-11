#{
#   "token" : {
#      "variables" : {
#         "command_" : [
#            "timer",
#            1465632809
#         ],
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

def each_command_token(token)
  yield token if token["variables"]["command_"].kind_of?(Array)
  
  if !token["childs"].empty?
    token["childs"].each do |child|
      each_command_token(child) { |match| yield match }
    end
  end
end

def http_get(uri)
  Net::HTTP.get(URI(uri))
end

#sample: http_post 'https://letsencrypt.up4sure.ch/up4sureSignup', 'application/json', '{"externalServerId":"ff825094-c5cf-4d2b-909a-2a06861f48f8","url":"http://www.tschenett.ch","email":"alert@tschenett.ch"}', { 'x-api-key' => 'xxx' }
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

def process_state(state)
  each_command_token(state["token"]) do |command_token|
    command = command_token["variables"]["command_"]
    if command[0] == "timer" && command[1].to_i < Time.new.to_i 
      definition_uuid = state["token"]["variables"]["definition_uuid"]
      instance_uuid = state["token"]["variables"]["instance_uuid"]
      token_uuid = command_token["uuid"]
      puts "Sending signal to definition #{definition_uuid}, instance #{instance_uuid}, token #{token_uuid}"
      http_post("http://localhost:8080/wf/#{definition_uuid}/#{instance_uuid}/#{token_uuid}", "application/json", {
        "command_" => ["notified", Time.new.to_i]
      }.to_json)
    end
  end
end

Dir[ARGV[0]].each do |file_name|
  next if File.directory? file_name
  process_state JSON.parse(File.read(file_name))
end
