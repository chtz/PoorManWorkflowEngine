require "./rbpm10.rb"

require "./test3_wf.rb"

instance = @definition.create

puts "*initial signal*"
instance.token.signal

Workflow.save_to_file(instance, "test3.dump")
