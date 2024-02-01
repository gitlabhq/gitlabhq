# frozen_string_literal: true

require_relative "helper"
require "sidekiq/job_logger"

describe "Job logger" do
  before do
    @output = StringIO.new
    @logger = Sidekiq::Logger.new(@output, level: :info)
    @logger.formatter = Sidekiq::Logger::Formatters::Pretty.new

    @cfg = reset!
    @cfg.logger = @logger

    Thread.current[:sidekiq_context] = nil
    Thread.current[:sidekiq_tid] = nil
  end

  after do
    Thread.current[:sidekiq_context] = nil
    Thread.current[:sidekiq_tid] = nil
  end

  it "tests pretty output" do
    jl = Sidekiq::JobLogger.new(@logger)

    # pretty
    p = @logger.formatter = Sidekiq::Logger::Formatters::Pretty.new
    job = {"jid" => "1234abc", "wrapped" => "FooJob", "class" => "Wrapper", "tags" => ["bar", "baz"]}
    # this mocks what Processor does
    jl.prepare(job) do
      jl.call(job, "queue") {}
    end

    a, b = @output.string.lines
    assert a
    assert b

    expected = /pid=#{$$} tid=#{p.tid} class=FooJob jid=1234abc tags=bar,baz/
    assert_match(expected, a)
    assert_match(expected, b)
    assert_match(/#{Time.now.utc.to_date}.+Z pid=#{$$} tid=#{p.tid} .+INFO: done/, b)
  end

  it "tests json output" do
    # json
    @logger.formatter = Sidekiq::Logger::Formatters::JSON.new
    jl = Sidekiq::JobLogger.new(@logger)
    job = {"jid" => "1234abc", "wrapped" => "Wrapper", "class" => "FooJob", "bid" => "b-xyz", "tags" => ["bar", "baz"]}
    # this mocks what Processor does
    jl.prepare(job) do
      jl.call(job, "queue") {}
    end
    a, b = @output.string.lines
    assert a
    assert b
    hsh = JSON.parse(a)
    keys = hsh.keys.sort
    assert_equal(["ctx", "lvl", "msg", "pid", "tid", "ts"], keys)
    keys = hsh["ctx"].keys.sort
    assert_equal(["bid", "class", "jid", "tags"], keys)
  end

  it "tests custom log level" do
    jl = Sidekiq::JobLogger.new(@logger)
    job = {"class" => "FooJob", "log_level" => "debug"}

    assert @logger.info?
    jl.prepare(job) do
      jl.call(job, "queue") do
        assert @logger.debug?
        @logger.debug("debug message")
      end
    end
    assert @logger.info?

    a, b, c = @output.string.lines
    assert_match(/INFO: start/, a)
    assert_match(/DEBUG: debug message/, b)
    assert_match(/INFO: done/, c)
  end

  it "tests custom logger with non numeric levels" do
    @logger = Logger.new(@output, level: :info)
    @cfg.logger = @logger

    jl = Sidekiq::JobLogger.new(@logger)
    job = {"class" => "FooJob", "log_level" => "debug"}

    assert @logger.info?
    refute @logger.debug?
    jl.prepare(job) do
      jl.call(job, "queue") do
        refute @logger.debug?
      end
    end
    assert @logger.info?
    refute @logger.debug?

    @logger.extend(Sidekiq::LoggingUtils)
    jl.prepare(job) do
      jl.call(job, "queue") do
        assert @logger.debug?
      end
    end
  end
end
