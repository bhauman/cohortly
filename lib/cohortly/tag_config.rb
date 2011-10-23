require 'singleton'
module Cohortly
  class TagConfig
    include Singleton
    attr_accessor :_tags, :_groups, :lookup_table
    def self.draw_tags(&block)
      instance._tags = []
      instance._groups = []      
      instance.lookup_table = {}
      instance.instance_eval(&block)
      instance.compile!
      instance
    end

    def tag(tag_name, &block)
      self._tags << Tag.new(tag_name, &block)
    end

    def tags(*args, &block)
      args.each {|x| tag(x, &block) }
    end
    
    def groups(*args)
      self._groups = *args.collect(&:to_s)
    end
    
    def compile!
      self._tags.each do |tag|
        tag._controllers.each do |cont|
          lookup_table[cont._name] ||= {}
          cont._acts.each do |a|
            lookup_table[cont._name][a] ||= []
            tag_names = lookup_table[cont._name][a] << tag._name
            lookup_table[cont._name][a] = tag_names.uniq
          end
        end
      end
    end

    def tags_for(controller, action = :_all)
      res = []
      if lookup_table[controller.to_sym]
        res += lookup_table[controller.to_sym][action.to_sym] || []
        res += lookup_table[controller.to_sym][:_all] || []
      end
      res.uniq.collect &:to_s
    end

    def self.tags_for(controller, action = :_all)
      return [] if controller.nil?
      instance.tags_for(controller, action)
    end

    def self.all_tags
      if instance._tags
        instance._tags.collect {|x| x._name.to_s }
      else
        []
      end
    end

    def self.all_groups
      instance._groups.sort
    end    

    class Tag
      attr_accessor :_name, :_controllers
      def initialize(tag_name, &block)
        self._controllers ||= []
        self._name = tag_name.to_sym
        instance_eval(&block)
      end
      def controller(controller_name, &block)
        _controllers << Controller.new(controller_name, &block)
      end
      def controllers(*args)
        args.each { |name| controller(name) { actions :_all } }
      end
    end

    class Controller
      attr_accessor :_name, :_acts
      def initialize(controller_name, &block)
        self._acts ||= []
        self._name = controller_name.to_sym
        self.instance_eval(&block)
      end

      def actions(*act_names)
        self._acts = act_names.collect &:to_sym
      end
    end
  end
end
