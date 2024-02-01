# frozen_string_literal: true

require_relative "helper"
require "sidekiq/logger"

describe "logger" do
  before do
    @output = StringIO.new
    @logger = Sidekiq::Logger.new(@output)
    @logger.formatter = Sidekiq::Logger::Formatters::Pretty.new
    @config = Sidekiq::Config.new

    Thread.current[:sidekiq_context] = nil
    Thread.current[:sidekiq_tid] = nil
  end

  after do
    Thread.current[:sidekiq_context] = nil
    Thread.current[:sidekiq_tid] = nil
  end

  it "tests default logger format" do
    assert_kind_of Sidekiq::Logger::Formatters::Pretty, @config.logger.formatter
  end

  it "tests heroku logger formatter" do
    ENV["DYNO"] = "dyno identifier"
    assert_kind_of Sidekiq::Logger::Formatters::WithoutTimestamp, @config.logger.formatter
  ensure
    ENV["DYNO"] = nil
  end

  it "tests with context" do
    subject = Sidekiq::Context
    assert_equal({}, subject.current)

    subject.with(a: 1) do
      assert_equal({a: 1}, subject.current)
    end

    assert_equal({}, subject.current)
  end

  it "tests with overlapping context" do
    subject = Sidekiq::Context
    subject.current[:foo] = "bar"
    assert_equal({foo: "bar"}, subject.current)

    subject.with(foo: "bingo") do
      assert_equal({foo: "bingo"}, subject.current)
    end

    assert_equal({foo: "bar"}, subject.current)
  end

  it "tests nested contexts" do
    subject = Sidekiq::Context
    assert_equal({}, subject.current)

    subject.with(a: 1) do
      assert_equal({a: 1}, subject.current)

      subject.with(b: 2, c: 3) do
        assert_equal({a: 1, b: 2, c: 3}, subject.current)
      end

      assert_equal({a: 1}, subject.current)
    end

    assert_equal({}, subject.current)
  end

  it "tests formatted output" do
    @logger.info("hello world")
    assert_match(/INFO: hello world/, @output.string)
    reset(@output)

    formats = [Sidekiq::Logger::Formatters::Pretty,
      Sidekiq::Logger::Formatters::WithoutTimestamp,
      Sidekiq::Logger::Formatters::JSON]
    formats.each do |fmt|
      @logger.formatter = fmt.new
      Sidekiq::Context.with(class: "HaikuJob", bid: "b-1234abc") do
        @logger.info("hello context")
      end
      assert_match(/INFO/, @output.string)
      assert_match(/hello context/, @output.string)
      assert_match(/b-1234abc/, @output.string)
      reset(@output)
    end
  end

  it "makes sure json output is parseable" do
    @logger.formatter = Sidekiq::Logger::Formatters::JSON.new

    @logger.debug("boom")
    Sidekiq::Context.with(class: "HaikuJob", jid: "1234abc") do
      @logger.info("json format")
    end
    a, b = @output.string.lines
    hash = JSON.parse(a)
    keys = hash.keys.sort
    assert_equal ["lvl", "msg", "pid", "tid", "ts"], keys
    assert_nil hash["ctx"]
    assert_equal hash["lvl"], "DEBUG"

    hash = JSON.parse(b)
    keys = hash.keys.sort
    assert_equal ["ctx", "lvl", "msg", "pid", "tid", "ts"], keys
    refute_nil hash["ctx"]
    assert_equal "1234abc", hash["ctx"]["jid"]
    assert_equal "INFO", hash["lvl"]
  end

  it "tests forwards logger kwards" do
    assert_silent do
      logger = Sidekiq::Logger.new("/dev/null", level: Logger::INFO)

      assert_equal Logger::INFO, logger.level
    end
  end

  it "tests log level query methods" do
    logger = Sidekiq::Logger.new("/dev/null", level: Logger::INFO)

    refute_predicate logger, :debug?
    assert_predicate logger, :info?
    assert_predicate logger, :warn?

    logger.level = Logger::WARN
    refute_predicate logger, :info?
    assert_predicate logger, :warn?
  end

  def reset(io)
    io.truncate(0)
    io.rewind
  end
end
