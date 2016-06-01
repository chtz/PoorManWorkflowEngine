require 'securerandom'

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
      
      def choose_transitions(token)
        transition_tokens = []
        @parent.transitions.each do |transition|
          next unless transition.source == self.name
          if transition.eval_condition(token)
            transition_token = transition_token(token)
            if transition_token
              transition_tokens << [transition, transition_token]
            end
          end
        end
        transition_tokens
      end
      
      def transition_token(token)
        token
      end
    end
    
    class StartNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
      end
    end
    
    class Node < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
      end
    end
    
    class StateNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        self.auto_signal = false
      end
    end
    
    class ForkNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
      end
      
      def transition_token(token)
        token.create_child
      end
    end
    
    class JoinNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
      end
      
      def transition_token(token)
        token.consume_child
      end
    end
    
    class EndNode < BaseNode
      def initialize(parent, name, options)
        super parent, name, options
        self.auto_signal = false
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
        elsif key.to_s =~ /(.+)_condition/
          transition = create_or_get_transition node.name, $1.to_sym
          transition.condition = value
        elsif key.to_s == "enter_action"
          node.enter_action = value
        elsif key.to_s == "leave_action"
          node.leave_action = value
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
    
    def fork_node(name, options = {})
      add_node ForkNode.new(self, name, options), options
    end
    
    def join_node(name, options = {})
      add_node JoinNode.new(self, name, options), options
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
      attr_accessor :uuid
      attr_accessor :parent
      attr_accessor :node
      attr_accessor :variables
      attr_accessor :root
      attr_accessor :childs
      
      def initialize(parent, node)
        self.uuid = SecureRandom.uuid
        self.parent = parent
        self.node = node
        self.variables = {}
        self.childs = []
      end
      
      def []=(index, val)
        @variables[index] = val
      end
      
      def [](index)
        @variables[index]
      end
      
      def create_child
        child = Token.new(self.parent, self.node)
        child.root = self
        self.childs << child
        child
      end
      
      def consume_child
        self.root.childs.delete self
        if self.root.childs.empty?
          self.root
        else
          nil
        end
      end
      
      def signal
        if self.childs.empty?
          current_node = @parent.definition.nodes[self.node]
        
          transition_tokens = current_node.choose_transitions(self)
          transition_tokens.each do |transition_token|
            transition,token = transition_token
          
            if current_node.leave_action
              current_node.leave_action.call(token)
            end
        
            target_node = @parent.definition.nodes[transition.destination]
            token.node = target_node.name
        
            if target_node.enter_action
              target_node.enter_action.call(token)
            end
        
            if target_node.auto_signal
              token.signal
            end
          end
        else
          self.childs[0].signal
        end
      end
      
      def marshal_dump
        [@uuid, @parent, @node, @variables, @root, @childs]
      end

      def marshal_load array
        @uuid, @parent, @node, @variables, @root, @childs = array
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

## DEMO ##

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
                puts "leave fork: #{token.uuid} #{token.root[:command]} #{token[:rand]}"
              }
              
  state_node  :state,
              :default_transition => :join,
              :enter_action => lambda { |token|
                puts "enter state: #{token.uuid} #{token.root[:command]} #{token[:rand]}"
              },
              :leave_action => lambda { |token|
                puts "leave state: #{token.uuid} #{token.root[:command]} #{token[:rand]}"
              }

  join_node   :join,
              :default_transition => :end,
              :enter_action => lambda { |token|
                puts "enter join: #{token.uuid} #{token.root[:command]} #{token[:rand]}"
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
  
  dump = Marshal.dump(instance)
  instance = Marshal.load(dump)
  instance.manual_initialize definition
end
