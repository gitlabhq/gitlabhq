# frozen_string_literal: true

require_relative "helper"

class InlineError < RuntimeError; end

class ParameterIsNotString < RuntimeError; end

class InlineJob
  include Sidekiq::Job
  def perform(pass)
    raise ArgumentError, "no jid" unless jid
    raise InlineError unless pass
  end
end

class InlineJobWithTimeParam
  include Sidekiq::Job
  def perform(time)
    raise ParameterIsNotString unless time.is_a?(String) || time.is_a?(Numeric)
  end
end

describe "Sidekiq::Testing.inline" do
  before do
    reset!
    require "sidekiq/testing/inline"
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.disable!
  end

  it "stubs the async call when in testing mode" do
    assert InlineJob.perform_async(true)

    assert_raises InlineError do
      InlineJob.perform_async(false)
    end
  end

  it "stubs the enqueue call when in testing mode" do
    assert Sidekiq::Client.enqueue(InlineJob, true)

    assert_raises InlineError do
      Sidekiq::Client.enqueue(InlineJob, false)
    end
  end

  it "stubs the push_bulk call when in testing mode" do
    assert Sidekiq::Client.push_bulk({"class" => InlineJob, "args" => [[true], [true]]})

    assert_raises InlineError do
      Sidekiq::Client.push_bulk({"class" => InlineJob, "args" => [[true], [false]]})
    end
  end

  it "should relay parameters through json" do
    assert Sidekiq::Client.enqueue(InlineJobWithTimeParam, Time.now.to_f)
  end
end
