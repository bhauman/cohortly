module Cohortly
  class TagConfig
    include Singleton
    attr_accessor :_tags, :lookup_table
    def self.draw_tags(&block)
      instance.instance_eval(&block)
      instance.compile!
      instance
    end

    def initialize
      self._tags ||= []
      self.lookup_table ||= {}
    end

    def tag(tag_name, &block)
      self._tags << Tag.new(tag_name, &block)
    end

    def tags(*args, &block)
      args.each {|x| tag(x, &block) }
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
      res += lookup_table[controller.to_sym][action.to_sym] || []
      res += lookup_table[controller.to_sym][:_all] || []
      res.uniq.collect &:to_s
    end

    def self.tags_for(controller, action = :_all)
      return [] if controller.nil?
      instance.tags_for(controller, action)
    end

    class Tag
      attr_accessor :_name, :_controllers
      def initialize(tag_name, &block)
        self._controllers ||= []
        self._name = tag_name
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
        self._name = controller_name
        self.instance_eval(&block)
      end

      def actions(*act_names)
        self._acts = act_names
      end
    end
  end
end