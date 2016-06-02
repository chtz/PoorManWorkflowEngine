require "./rbpm10.rb"

definition = Workflow.define do 
  start_node  :start,   
              :default_transition => :fork
                        
  fork_node   :fork,
              :a_transition => :state_a,
              :b_transition => :state_b
              
  state_node  :state_a,
              :default_transition => :join,
              :enter_action => lambda { |token|
                token[:command] = "RANDOM"
              },
              :leave_action => lambda { |token|
                puts "a rand: #{token[:random]}"
              }
              
  state_node  :state_b,
              :default_transition => :join,
              :enter_action => lambda { |token|
                token[:command] = "RANDOM"
              },
              :leave_action => lambda { |token|
                token[:random] = token[:random] * -1
                puts "b rand: #{token[:random]}"
              }            

  join_node   :join,
              :default_transition => :end,
              :enter_action => lambda { |token|
                unless token.parent[:sum]
                  token.parent[:sum] = token[:random]
                else
                  token.parent[:sum] = token.parent[:sum] + token[:random]
                end
              },
              :leave_action => lambda { |token|
                puts "sum: #{token[:sum]}"
              }
              
  end_node    :end
end

instance = definition.create

puts "*initial signal*"
instance.token.signal

while not instance.done?
  signal_sent = false
  instance.state_tokens do |token|
    if token[:command] = "RANDOM"
      token[:random] = (rand*1000).to_i
      
      puts "*state signal*"
      token.signal
      signal_sent = true
      break
    end
  end
  
  raise unless signal_sent
  
  dump = Workflow.save(instance)
  instance = Workflow.load(definition, dump)
end
