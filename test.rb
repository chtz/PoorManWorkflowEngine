require 'json'

module Workflow
  class WorkflowDefinition
    attr_accessor :start
    attr_accessor :end
    attr_accessor :nodes
    attr_accessor :transitions
    
    class Transition
      attr_accessor :source
      attr_accessor :name
      attr_accessor :destination
      attr_accessor :condition
      
      def initialize(parent, source, name)
        @parent = parent
        self.source = source
        self.name = name
        #puts "new transition: #{source}.#{name}"
      end
      
      def eval_condition(token)
        return true unless self.condition
        token.instance_eval(self.condition)
      end
    end
    
    class BaseNode
      attr_accessor :name
      attr_accessor :auto_signal
      attr_accessor :enter_action
      attr_accessor :leave_action
      
      def initialize(parent, name, options)
        @parent = parent
        self.name = name
        self.auto_signal = true
      end
      
      def choose_transition(token)
        @parent.transitions.each do |transition|
          next unless transition.source == self.name
          if transition.eval_condition(token)
            return transition
          end
        end
        nil
      end
    end
    
    class StartNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        #puts "new start node: #{name}"
      end
    end
    
    class Node < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        #puts "new node: #{name}"
      end
    end
    
    class StateNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        self.auto_signal = false
        #puts "new state node: #{name}"
      end
    end
    
    class EndNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        self.auto_signal = false
        #puts "new end node: #{name}"
      end
    end
    
    def initialize()
      self.nodes = {}
      self.transitions = []
    end
    
    def create_or_get_transition(source, name)
      transition = self.transitions.select { |t| t.source == source and t.name == name }.first
      unless transition
        transition = Transition.new(self, source, name)
        self.transitions << transition
      end
      transition
    end
    
    def add_node(node, options)
      self.nodes[node.name] = node
      
      options.each do |key,value|
        if key.to_s =~ /(.+)_transition/
          transition = create_or_get_transition node.name, $1.to_sym
          transition.destination = value
          #puts "  destination: #{value}"
        elsif key.to_s =~ /(.+)_condition/
          transition = create_or_get_transition node.name, $1.to_sym
          transition.condition = value
          #puts "  condition: #{value}"
        elsif key.to_s == "enter_action"
          node.enter_action = value
          #puts "  action: #{value}"
        elsif key.to_s == "leave_action"
          node.leave_action = value
          #puts "  action: #{value}"
        end
      end
    end
    
    def start_node(name, options)
      self.start = name
      add_node StartNode.new(self, name, options), options
    end
    
    def node(name, options, &block)
      add_node Node.new(self, name, options), options
    end
    
    def state_node(name, options = {})
      add_node StateNode.new(self, name, options), options
    end
    
    def end_node(name, options = {})
      self.end = name
      add_node EndNode.new(self, name, options), options
    end
    
    def create
      Workflow.new(self)
    end
  end
  
  def self.define(&block)
    definition = WorkflowDefinition.new
    definition.instance_eval(&block)
    definition
  end
  
  class Workflow 
    attr_accessor :definition
    attr_accessor :token
    
    class Token
      attr_accessor :parent
      attr_accessor :node
      attr_accessor :variables
      
      def initialize(parent, node)
        self.parent = parent
        self.node = node
        self.variables = {}
      end
      
      def signal
        current_node = @parent.definition.nodes[self.node]
        
        if current_node.leave_action
          current_node.leave_action.call(self)
        end
        
        transition = current_node.choose_transition(self)
        target_node = @parent.definition.nodes[transition.destination]
        #puts "transition from #{node} via #{transition.name} to #{target_node.name}"
        self.node = target_node.name
        
        if target_node.enter_action
          target_node.enter_action.call(self)
        end
        
        if target_node.auto_signal
          self.signal
        end
      end
      
      def marshal_dump
        [@node, @variables]
      end

      def marshal_load array
        @node, @variables = array
      end
    end
    
    def initialize(definition)
      self.definition = definition
      self.token = Token.new(self, definition.start)
    end
    
    def manual_initialize(definition)
      self.definition = definition
      self.token.parent = self
    end
    
    def done?
      self.token.node == self.definition.end
    end
    
    def marshal_dump
      @token
    end

    def marshal_load value
      @token = value
    end
  end
end

definition = Workflow.define do 
  start_node  :start,   
              :a_transition => :middle_a, :a_condition => "variables[:command] == :cmd_a",
              :b_transition => :middle_b, :b_condition => "variables[:command] == :cmd_b"
                        
  node        :middle_a,  
              :default_transition => :state,
              :enter_action => lambda { |token|
                puts "middle a action: #{token.variables[:command]}"
              }
              
  node        :middle_b,
              :default_transition => :state,
              :enter_action => lambda { |token|
                puts "middle b action: #{token.variables[:command]}"
              }
      
  state_node  :state,
              :default_transition => :end,
              :enter_action => lambda { |token|
                puts "state enter action: #{token.variables[:command]}"
              },
              :leave_action => lambda { |token|
                puts "state leave action: #{token.variables[:command]}"
              }
              
  end_node    :end,
              :enter_action => lambda { |token|
                puts "end action: #{token.variables[:command]}"
              }
end

instance = definition.create
instance.token.variables[:command] = :cmd_b

while not instance.done?
  puts "send signal"  
  instance.token.signal
  instance.token.variables[:command] = :foo
  
  dump = Marshal.dump(instance)
  instance = Marshal.load(dump)
  instance.manual_initialize definition
end

def http_get(response_token)
  puts "enter"
end

definition = Workflow.define do 
  start_node  :start,   
              :default_transition => :state
                        
  state_node  :state,
              :default_transition => :end,
              :enter_action => lambda { |token|
                http_get token
              },
              :leave_action => lambda { |token|
                puts "leave"
              }
              
  end_node    :end
end

instance = definition.create
instance.token.signal

dump = Marshal.dump(instance)
instance = Marshal.load(dump)
instance.manual_initialize definition

instance.token.signal
