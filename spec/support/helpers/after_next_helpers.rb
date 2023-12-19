# frozen_string_literal: true

require 'gitlab/rspec/next_instance_of'

module AfterNextHelpers
  class DeferredExpectation
    include ::NextInstanceOf
    include ::RSpec::Matchers
    include ::RSpec::Mocks::ExampleMethods

    def initialize(klass, args, level:)
      @klass = klass
      @args = args
      @level = level.to_sym
    end

    def to(condition)
      run_condition(condition, asserted: true)
    end

    def not_to(condition)
      run_condition(condition, asserted: false)
    end

    private

    attr_reader :klass, :args, :level

    def run_condition(condition, asserted:)
      msg = asserted ? :to : :not_to
      case level
      when :expect
        if asserted
          expect_next_instance_of(klass, *args) { |instance| expect(instance).send(msg, condition) }
        else
          allow_next_instance_of(klass, *args) { |instance| expect(instance).send(msg, condition) }
        end
      when :allow
        allow_next_instance_of(klass, *args) { |instance| allow(instance).send(msg, condition) }
      else
        raise "Unknown level: #{level}"
      end
    end
  end

  def allow_next(klass, *args)
    DeferredExpectation.new(klass, args, level: :allow)
  end

  def expect_next(klass, *args)
    DeferredExpectation.new(klass, args, level: :expect)
  end
end
