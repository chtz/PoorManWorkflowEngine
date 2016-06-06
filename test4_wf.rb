@definition = Workflow.define do 
  start_node  :start,   
              :default_transition => :state_a
              
  state_node  :state_a,
              :default_transition => :state_b,
              :enter_action => lambda { |token|
                token["command"] = ["HTTPGET", "www.tschenett.ch"]
              },
              :leave_action => lambda { |token|
                if  token["result"] =~ /access (.+)\./m
                  token.variables.delete "result"
                  token["extracted.access"] = $1
                end
              }
              
  state_node :state_b,
             :default_transition => :state_c,
             :enter_action => lambda { |token|
               token["command"] = ["HTTPGET", "www.furthermore.ch"]
             },
             :leave_action => lambda { |token|
               if  token["result"] =~ /access (.+)\./m
                 token.variables.delete "result"
                 token["extracted.access2"] = $1
               end
             }
                            
  state_node :state_c,
             :default_transition => :state_d
              
  state_node :state_d,
             :default_transition => :state_c,
             :enter_action => lambda { |token|
               token["command"] = ["HTTPGET", "www.up4sure.ch"]
             },
             :leave_action => lambda { |token|
               if  token["result"] =~ /access (.+)\./m
                 token.variables.delete "result"
                 token["extracted.access3"] = $1
               end
             }
                            
  end_node   :end
end
