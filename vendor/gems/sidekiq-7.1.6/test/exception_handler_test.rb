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

class SErrorHandler
  def call(x, y)
    raise SystemStackError
  end
end

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

    it "handles exceptions in classy error handlers" do
      test_handler = SErrorHandler.new
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

    it "handles exceptions in error handlers" do
      test_handler = ->(_ex, _ctx) { raise SystemStackError }
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
