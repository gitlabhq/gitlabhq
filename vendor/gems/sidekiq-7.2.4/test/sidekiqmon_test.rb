# frozen_string_literal: true

require_relative "helper"
require "sidekiq/monitor"

def capture_stdout
  $stdout = StringIO.new
  yield
  $stdout.string.chomp
ensure
  $stdout = STDOUT
end

def output(section = "all")
  capture_stdout do
    Sidekiq::Monitor::Status.new.display(section)
  end
end

describe Sidekiq::Monitor do
  before do
    @config = reset!
  end

  describe "status" do
    describe "version" do
      it "displays the current Sidekiq version" do
        assert_includes output, "Sidekiq #{Sidekiq::VERSION}"
      end

      it "displays the current time" do
        Time.stub(:now, Time.at(0)) do
          assert_includes output, Time.at(0).utc.to_s
        end
      end
    end

    describe "overview" do
      it "has a heading" do
        assert_includes output, "---- Overview ----"
      end

      it "displays the correct output" do
        mock_stats = OpenStruct.new(
          processed: 420710,
          failed: 12,
          workers_size: 34,
          enqueued: 56,
          retry_size: 78,
          scheduled_size: 90,
          dead_size: 666
        )
        Sidekiq::Stats.stub(:new, mock_stats) do
          assert_includes output, "Processed: 420,710"
          assert_includes output, "Failed: 12"
          assert_includes output, "Busy: 34"
          assert_includes output, "Enqueued: 56"
          assert_includes output, "Retries: 78"
          assert_includes output, "Scheduled: 90"
          assert_includes output, "Dead: 666"
        end
      end
    end

    describe "processes" do
      it "has a heading" do
        assert_includes output, "---- Processes (0) ----"
      end

      it "displays the correct output" do
        mock_processes = [{
          "identity" => "foobar",
          "tag" => "baz",
          "started_at" => Time.now,
          "concurrency" => 5,
          "busy" => 2,
          "queues" => %w[low medium high]
        }]
        Sidekiq::ProcessSet.stub(:new, mock_processes) do
          assert_includes output, "foobar [baz]"
          assert_includes output, "Started: #{mock_processes.first["started_at"]} (just now)"
          assert_includes output, "Threads: 5 (2 busy)"
          assert_includes output, "Queues: high, low, medium"
        end
      end
    end

    describe "queues" do
      it "has a heading" do
        assert_includes output, "---- Queues (0) ----"
      end

      it "displays the correct output" do
        mock_queues = [
          OpenStruct.new(name: "foobar", size: 12, latency: 12.3456),
          OpenStruct.new(name: "a_long_queue_name", size: 234, latency: 567.89999)
        ]
        Sidekiq::Queue.stub(:all, mock_queues) do
          assert_includes output, "NAME                 SIZE  LATENCY"
          assert_includes output, "foobar                 12    12.35"
          assert_includes output, "a_long_queue_name     234   567.90"
        end
      end
    end
  end
end
