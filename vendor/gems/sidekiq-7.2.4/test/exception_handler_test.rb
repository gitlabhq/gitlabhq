# frozen_string_literal: true

require_relative "helper"
require "sidekiq/component"
require "sidekiq/rails"
require "stringio"
require "logger"

ExceptionHandlerTestException = Class.new(StandardError)
TEST_EXCEPTION = ExceptionHandlerTestException.new("Something didn't work!")

class Thing
  include Sidekiq::Component
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def invoke_exception(args)
    raise TEST_EXCEPTION
  rescue ExceptionHandlerTestException => e
    handle_exception(e, args)
  end
end

class ClassyErrorHandler1
  def call(x, y)
    raise SystemStackError
  end
end

class ClassyErrorHandler2
  def call(x, y, z)
    raise SystemStackError
  end
end

class ClassyErrorHandler3
  def call(x, y, z = nil)
    raise SystemStackError
  end
end

CLASSY_ERROR_HANDLER1 = ClassyErrorHandler1.new
CLASSY_ERROR_HANDLER2 = ClassyErrorHandler2.new
CLASSY_ERROR_HANDLER3 = ClassyErrorHandler3.new

LAMBDA_ERROR_HANDLER1 = ->(_ex, _ctx) { raise SystemStackError }
LAMBDA_ERROR_HANDLER2 = ->(_ex, _ctx, _cfg) { raise SystemStackError }
LAMBDA_ERROR_HANDLER3 = ->(_ex, _ctx, _cfg = nil) { raise SystemStackError }

PROC_ERROR_HANDLER1 = proc { |_ex, _ctx| raise SystemStackError }
PROC_ERROR_HANDLER2 = proc { |_ex, _ctx, _cfg| raise SystemStackError }
PROC_ERROR_HANDLER3 = proc { |_ex, _ctx, _cfg = nil| raise SystemStackError }

VALID_ERROR_HANDLERS = %w[
  CLASSY_ERROR_HANDLER2
  CLASSY_ERROR_HANDLER3
  LAMBDA_ERROR_HANDLER2
  LAMBDA_ERROR_HANDLER3
  PROC_ERROR_HANDLER2
  PROC_ERROR_HANDLER3
]
DEPRECATED_ERROR_HANDLERS = %w[
  CLASSY_ERROR_HANDLER1
  LAMBDA_ERROR_HANDLER1
  PROC_ERROR_HANDLER1
]

describe Sidekiq::Component do
  describe "with mock logger" do
    before do
      @config = reset!
    end

    it "logs the exception to Sidekiq.logger" do
      @config[:reloader] = Sidekiq::Rails::Reloader.new
      output = capture_logging(@config) do
        Thing.new(@config).invoke_exception(a: 1)
      end
      assert_match(/"a":1/, output, "didn't include the context")
      assert_match(/Something didn't work!/, output, "didn't include the exception message")
      assert_match(/test\/exception_handler_test.rb/, output, "didn't include the backtrace")
    end

    VALID_ERROR_HANDLERS.each do |handler_name|
      it "handles exceptions in #{handler_name} without DEPRECATION" do
        test_handler = self.class.const_get(handler_name)
        @config[:error_handlers] << test_handler
        output = capture_logging(@config) do
          Thing.new(@config).invoke_exception(a: 1)
        end

        refute_match(/DEPRECATION/, output, "didn't include the deprecation warning")
        assert_match(/SystemStackError/, output, "didn't include the exception")
        assert_match(/Something didn't work!/, output, "didn't include the exception message")
        assert_match(/!!! ERROR HANDLER THREW AN ERROR !!!/, output, "didn't include error handler problem message")
      ensure
        @config[:error_handlers].delete(test_handler)
      end
    end

    DEPRECATED_ERROR_HANDLERS.each do |handler_name|
      it "handles exceptions in #{handler_name} with DEPRECATION" do
        test_handler = self.class.const_get(handler_name)
        @config[:error_handlers] << test_handler
        output = capture_logging(@config) do
          Thing.new(@config).invoke_exception(a: 1)
        end

        assert_match(/DEPRECATION/, output, "didn't include the deprecation warning")
        assert_match(/SystemStackError/, output, "didn't include the exception")
        assert_match(/Something didn't work!/, output, "didn't include the exception message")
        assert_match(/!!! ERROR HANDLER THREW AN ERROR !!!/, output, "didn't include error handler problem message")
      ensure
        @config[:error_handlers].delete(test_handler)
      end
    end

    it "cleans a backtrace if there is a cleaner" do
      @config[:backtrace_cleaner] = ->(backtrace) { backtrace.take(1) }
      output = capture_logging(@config) do
        Thing.new(@config).invoke_exception(a: 1)
      end

      assert_equal 1, output.lines.count { |line| line.match?(/\d+:in/) }
    ensure
      @config[:backtrace_cleaner] = Sidekiq::Config::DEFAULTS[:backtrace_cleaner]
    end

    describe "when the exception does not have a backtrace" do
      it "does not fail" do
        exception = ExceptionHandlerTestException.new
        assert_nil exception.backtrace

        Thing.new(@config).handle_exception exception
      end
    end
  end
end
