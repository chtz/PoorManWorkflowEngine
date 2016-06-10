@definition = Workflow.define do 
  start_node  :start,   
              :default_transition => :fork

  fork_node   :fork,
          :a_transition => :state_a,
              :b_transition => :state_b
              
  state_node  :state_a,
              :default_transition => :join,
              :enter_action => lambda { |token|
                token["command"] = ["http_get", "http://tschenett.ch"]
              },
              :leave_action => lambda { |token|
                if  token["result"] =~ /\<title\>(.+?)\<\/title\>/m
                  token.parent["tschenett.title"] = $1
                end
              }
              
  state_node :state_b,
             :default_transition => :join,
             :enter_action => lambda { |token|
               token["domain"] = "furthermore.ch"
               token["command"] = ["http_get", "http://{{domain}}"]
             },
             :leave_action => lambda { |token|
               if  token["result"] =~ /\<title\>(.+?)\<\/title\>/m
                 token.parent["furthermore.title"] = $1
               end
             }
                           
  join_node  :join,
             :default_transition => :state_c
 
  state_node :state_c,
             :default_transition => :state_d
              
  state_node :state_d,
             :default_transition => :state_e,
             :enter_action => lambda { |token|
               token["command"] = ["http_get", "https://www.up4sure.ch"]
             },
             :leave_action => lambda { |token|
               if  token["result"] =~ /\<title\>(.+?)\<\/title\>/m
                 token.variables.delete "result"
                 token["up4sure.title"] = $1
               end
             }

  state_node :state_e,
             :default_transition => :end,
             :enter_action => lambda { |token|
               token["command"] = ["http_post", "https://letsencrypt.up4sure.ch/up4sureSignup", "application/json", '{"externalServerId":"ff825093-c5cf-4d2b-909a-2a06861f48f8","url":"http://www.tschenett.ch","email":"alert@tschenett.ch"}', { 'x-api-key' => 'ky6bg0mCmz8Vxe6cRiMqs7jv1MLWjGEJ7olKgLRq' }]
             }      
                            
  end_node   :end
end
