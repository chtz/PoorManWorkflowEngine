require "./rbpm10.rb"

require "./test3_wf.rb"

instance = @definition.create

puts "*initial signal*"
instance.token.signal

dump = Workflow.save(instance)
File.open("test3.dump", 'w') { |file| file.write(dump) }
