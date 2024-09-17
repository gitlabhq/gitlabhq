# frozen_string_literal: true

require_relative "helper"
require "sidekiq/launcher"

describe Sidekiq::Launcher do
  before do
    @config = reset!
    @config.default_capsule.concurrency = 3
    @config[:tag] = "myapp"
  end

  describe "memory collection" do
    it "works in any test environment" do
      kb = Sidekiq::Launcher::MEMORY_GRABBER.call($$)
      refute_nil kb
      assert kb > 0
    end
  end

  it "starts and stops" do
    l = Sidekiq::Launcher.new(@config)
    l.run(async_beat: false)
    l.stop
  end

  describe "heartbeat" do
    before do
      @launcher = Sidekiq::Launcher.new(@config)
      @id = @launcher.identity

      Sidekiq::Processor::WORK_STATE.set("a", {"b" => 1})

      @proctitle = $0
    end

    after do
      Sidekiq::Processor::WORK_STATE.clear
      $0 = @proctitle
    end

    it "stores process info in redis" do
      @launcher.beat

      assert_equal "sidekiq #{Sidekiq::VERSION} myapp [1 of 3 busy]", $0
      workers, rtt = @config.redis { |c| c.hmget(@id, "busy", "rtt_us") }

      assert_equal "1", workers
      refute_nil rtt
      assert_in_delta 1000, rtt.to_i, 1000

      expires = @config.redis { |c| c.pttl(@id) }
      assert_in_delta 60000, expires, 500
    end

    it "fires start heartbeat event only once" do
      cnt = 0

      @config.on(:heartbeat) do
        cnt += 1
      end
      assert_equal 0, cnt
      @launcher.heartbeat
      assert_equal 1, cnt
      @launcher.heartbeat
      assert_equal 1, cnt
    end

    it "quiets" do
      @launcher.quiet
      @launcher.beat

      assert_equal "sidekiq #{Sidekiq::VERSION} myapp [1 of 3 busy] stopping", $0

      @launcher.beat
      info = @config.redis { |c| c.hmget(@id, "busy") }
      assert_equal ["1"], info

      expires = @config.redis { |c| c.pttl(@id) }
      assert_in_delta 60000, expires, 50
    end

    it "allows arbitrary proctitle extensions" do
      Sidekiq::Launcher::PROCTITLES << proc { "xyz" }
      @launcher.beat
      Sidekiq::Launcher::PROCTITLES.pop
      assert_equal "sidekiq #{Sidekiq::VERSION} myapp [1 of 3 busy] xyz", $0
    end
  end
end
