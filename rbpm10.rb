require 'securerandom'
require 'json'

module Workflow
  class Transition
    attr_accessor :source
    attr_accessor :name
    attr_accessor :destination
    attr_accessor :condition
    
    def initialize(source, name)
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
    
    def initialize(definition, name)
      @definition = definition
      self.name = name
    end
    
    def choose_transitions(token)
      transition_tokens = []
      @definition.transitions.each do |transition|
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
  end
  
  class Node < BaseNode
    def initialize(definition, name)
      super definition, name
      self.auto_signal = true
    end
    
    def transition_token(token)
      token
    end
  end
  
  class StateNode < BaseNode
    def initialize(definition, name)
      super definition, name
      self.auto_signal = false
    end
    
    def transition_token(token)
      token
    end
  end
  
  class ForkNode < BaseNode
    def initialize(definition, name)
      super definition, name
      self.auto_signal = true
    end
    
    def transition_token(token)
      token.create_child
    end
  end
  
  class JoinNode < BaseNode
    def initialize(definition, name)
      super definition, name
      self.auto_signal = true
    end
    
    def transition_token(token)
      token.consume_child
    end
  end
  
  class EndNode < BaseNode
    def initialize(definition, name)
      super definition, name
      self.auto_signal = true
    end
    
    def transition_token(token)
      nil
    end
  end
    
  class WorkflowDefinition
    attr_accessor :start
    attr_accessor :end
    attr_accessor :nodes
    attr_accessor :transitions
      
    def initialize()
      self.nodes = {}
      self.transitions = []
    end
    
    def create_or_get_transition(source, name)
      transition = self.transitions.select { |t| t.source == source and t.name == name }.first
      unless transition
        transition = Transition.new(source, name)
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
      add_node Node.new(self, name), options
    end
    
    def node(name, options, &block)
      add_node Node.new(self, name), options
    end
    
    def state_node(name, options = {})
      add_node StateNode.new(self, name), options
    end
    
    def fork_node(name, options = {})
      add_node ForkNode.new(self, name), options
    end
    
    def join_node(name, options = {})
      add_node JoinNode.new(self, name), options
    end
    
    def end_node(name, options = {})
      self.end = name
      add_node EndNode.new(self, name), options
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
    
  class Token
    attr_accessor :uuid
    attr_accessor :node
    attr_accessor :variables
    attr_accessor :parent
    attr_accessor :childs
    
    def initialize(workflow, node)
      @workflow=workflow
      self.uuid = SecureRandom.uuid
      self.node = node
      self.variables = {}
      self.childs = []
    end
    
    def self.from_hash(workflow, parent, h)
      token = Token.new(workflow, h["node"].to_sym)
      token.uuid = h["uuid"]
      token.variables = h["variables"]
      token.parent = parent
      childs = []
      h["childs"].each do |ch|
        childs << Token.from_hash(workflow, token, ch)
      end
      token.childs = childs
      token
    end
    
    def to_hash
      childs=[]
      self.childs.each do |child|
        childs << child.to_hash
      end
      h = {
        "uuid" => self.uuid,
        "node" => self.node,
        "variables" => self.variables,
        "childs" => childs
      }
    end
    
    def []=(index, val)
      @variables[index] = val
    end
    
    def [](index)
      @variables[index]
    end
    
    def create_child
      child = Token.new(@workflow, self.node)
      child.parent = self
      self.childs << child
      child
    end
    
    def consume_child
      self.parent.childs.delete self
      if self.parent.childs.empty?
        self.parent
      else
        nil
      end
    end
    
    def current_node
      @workflow.definition.nodes[self.node]
    end
    
    def signal
      if self.childs.empty?
        c_node = current_node
      
        transition_tokens = c_node.choose_transitions(self)
        transition_tokens.each do |transition_token|
          transition,token = transition_token
        
          if c_node.leave_action
            c_node.leave_action.call(token)
          end
      
          target_node = @workflow.definition.nodes[transition.destination]
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
      [@workflow, @uuid, @node, @variables, @parent, @childs]
    end

    def marshal_load array
      @workflow, @uuid, @node, @variables, @parent, @childs = array
    end
  end
    
  class Workflow 
    attr_accessor :uuid
    attr_accessor :definition
    attr_accessor :token
      
    def initialize(definition)
      self.definition = definition
      self.uuid = SecureRandom.uuid
      self.token = Token.new(self, definition.start)
    end
    
    def self.from_hash(definition, h)
      workflow = Workflow.new(definition)
      workflow.uuid = h["uuid"]
      workflow.token = Token.from_hash(workflow, nil, h["token"])
      workflow
    end
    
    def to_hash
      h = { 
        "uuid" => self.uuid, 
        "token" => self.token.to_hash
      }
    end
    
    def state_tokens(token = nil)
      token = self.token unless token
      unless token.childs.empty?
        token.childs.each do |child|
          state_tokens(child) { |token| yield token unless token.current_node.auto_signal }
        end
      else
        yield token unless token.current_node.auto_signal
      end
    end
    
    def done?
      self.token.node == self.definition.end
    end
    
    def marshal_dump
      [@uuid, @token]
    end

    def marshal_load value
      @uuid, @token = value
    end
  end
  
  def self.save(instance)
    instance.to_hash.to_json
  end
  
  def self.save_to_file(instance, file)
    dump = self.save(instance)
    File.open(file, 'w') { |file| file.write(dump) }
  end
  
  def self.load(definition, dump)
    Workflow.from_hash(definition, JSON.parse(dump))
  end
  
  def self.load_from_file(definition, file)
    dump = File.read(file)
    self.load(definition, dump)
  end
end
