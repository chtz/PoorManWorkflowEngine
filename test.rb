require "./rbpm10.rb"

definition = Workflow.define do 
  start_node  :start,   
              :a_transition => :middle_a, :a_condition => "variables[:command] == :cmd_a",
              :b_transition => :middle_b, :b_condition => "variables[:command] == :cmd_b"
                        
  node        :middle_a,  
              :default_transition => :fork,
              :enter_action => lambda { |token|
                puts "enter middle_a: #{token.uuid} #{token[:command]}"
              }
              
  node        :middle_b,
              :default_transition => :fork,
              :enter_action => lambda { |token|
                puts "enter middle_b: #{token.uuid} #{token[:command]}"
              }
  
  fork_node   :fork,
              :a_transition => :state,
              :b_transition => :state,
              :leave_action => lambda { |token|
                token[:rand] = (rand*1000).to_i
                puts "leave fork: #{token.uuid} #{token.parent[:command]} #{token[:rand]}"
              }
              
  state_node  :state,
              :default_transition => :join,
              :enter_action => lambda { |token|
                puts "enter state: #{token.uuid} #{token.parent[:command]} #{token[:rand]}"
              },
              :leave_action => lambda { |token|
                puts "leave state: #{token.uuid} #{token.parent[:command]} #{token[:rand]}"
              }

  join_node   :join,
              :default_transition => :end,
              :enter_action => lambda { |token|
                puts "enter join: #{token.uuid} #{token.parent[:command]} #{token[:rand]}"
              }
              
  end_node    :end,
              :enter_action => lambda { |token|
                puts "enter end: #{token.uuid} #{token[:command]} #{token[:rand]}"
              }
end

instance = definition.create
instance.token[:command] = :cmd_b

while not instance.done?
  puts "*** send signal ***"  
  instance.token.signal
  instance.token[:command] = instance.token[:command].to_s + "_x"
  
  dump = Workflow.save(instance)
  instance = Workflow.load(definition, dump)
end
