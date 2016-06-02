require "./rbpm10.rb"

require "./test3_wf.rb"

instance = Workflow.load_from_file @definition, "test3.dump"

unless instance.done?
  instance.state_tokens do |token|
    if token[:command] = "RANDOM"
      token[:result] = (rand*1000).to_i
      
      puts "*state signal*"
      token.signal
      signal_sent = true
      break
    end
  end
  
  Workflow.save_to_file(instance, "test3.dump")
end
