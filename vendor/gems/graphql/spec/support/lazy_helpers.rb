# frozen_string_literal: true
module LazyHelpers
  MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK = 44
  MAGIC_NUMBER_THAT_RETURNS_NIL = 0
  MAGIC_NUMBER_THAT_RAISES_ERROR = 13
  class Wrapper
    def initialize(item = nil, &block)
      if block
        @block = block
      else
        @item = item
      end
    end

    def item
      if @block
        @item = @block.call()
        @block = nil
      end
      @item
    end
  end

  class SumAll
    attr_reader :own_value
    attr_writer :value

    def initialize(own_value)
      @own_value = own_value
      all << self
    end

    def value
      @value ||= begin
        total_value = all.map(&:own_value).reduce(&:+)
        all.each { |v| v.value = total_value}
        all.clear
        total_value
      end
      @value
    end

    def all
      self.class.all
    end

    def self.all
      @all ||= []
    end
  end

  class LazySum < GraphQL::Schema::Object
    field :value, Integer
    def value
      if object == MAGIC_NUMBER_THAT_RAISES_ERROR
        nil
      else
        object
      end
    end

    def self.authorized?(obj, ctx)
      if obj == MAGIC_NUMBER_WITH_LAZY_AUTHORIZED_HOOK
        Wrapper.new { true }
      else
        true
      end
    end

    field :nested_sum, LazySum, null: false do
      argument :value, Integer
    end

    def nested_sum(value:)
      if value == MAGIC_NUMBER_THAT_RAISES_ERROR
        Wrapper.new(nil)
      else
        SumAll.new(@object + value)
      end
    end

    field :nullable_nested_sum, LazySum do
      argument :value, Integer
    end
    alias :nullable_nested_sum :nested_sum
  end

  class LazyQuery < GraphQL::Schema::Object
    field :int, Integer, null: false do
      argument :value, Integer
      argument :plus, Integer, required: false, default_value: 0
    end
    def int(value:, plus:)
      Wrapper.new(value + plus)
    end

    field :nested_sum, LazySum, null: false do
      argument :value, Integer
    end

    def nested_sum(value:)
      SumAll.new(value)
    end

    field :nullable_nested_sum, LazySum do
      argument :value, Integer
    end

    def nullable_nested_sum(value:)
      if value == MAGIC_NUMBER_THAT_RAISES_ERROR
        Wrapper.new { raise GraphQL::ExecutionError.new("#{MAGIC_NUMBER_THAT_RAISES_ERROR} is unlucky") }
      elsif value == MAGIC_NUMBER_THAT_RETURNS_NIL
        nil
      else
        SumAll.new(value)
      end
    end

    field :list_sum, [LazySum, null: true] do
      argument :values, [Integer]
    end
    def list_sum(values:)
      values.map { |v| v == MAGIC_NUMBER_THAT_RETURNS_NIL ? nil : v }
    end
  end

  module SumAllInstrumentation
    def execute_query(query:)
      add_check(query, "before #{query.selected_operation.name}")
      super
    end

    def execute_query_lazy(query:, multiplex:)
      result = super
      multiplex.queries.reverse_each do |q|
        add_check(q, "after #{q.selected_operation.name}")
      end
      result
    end

    def execute_multiplex(multiplex:)
      add_check(multiplex, "before multiplex 1")
      # TODO not threadsafe
      # This should use multiplex-level context
      SumAll.all.clear
      result = super
      add_check(multiplex, "after multiplex 1")
      result
    end

    private

    def add_check(object, text)
      checks = object.context[:instrumentation_checks]
      if checks
        checks << text
      end
    end
  end

  module SumAllInstrumentation2
    def execute_multiplex(multiplex:)
      add_check(multiplex, "before multiplex 2")
      result = super
      add_check(multiplex, "after multiplex 2")
      result
    end

    private

    def add_check(object, text)
      checks = object.context[:instrumentation_checks]
      if checks
        checks << text
      end
    end
  end
  class LazySchema < GraphQL::Schema
    query(LazyQuery)
    mutation(LazyQuery)
    lazy_resolve(Wrapper, :item)
    lazy_resolve(SumAll, :value)
    trace_with(SumAllInstrumentation2)
    trace_with(SumAllInstrumentation)

    def self.sync_lazy(lazy)
      if lazy.is_a?(SumAll) && lazy.own_value > 1000
        lazy.value # clear the previous set
        lazy.own_value - 900
      else
        super
      end
    end
  end

  def run_query(query_str, **rest)
    LazySchema.execute(query_str, **rest)
  end
end
