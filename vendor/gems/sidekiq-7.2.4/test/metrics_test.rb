# frozen_string_literal: true

require_relative "helper"
require "sidekiq/component"
require "sidekiq/metrics/tracking"
require "sidekiq/metrics/query"
require "sidekiq/deploy"
require "sidekiq/api"

describe Sidekiq::Metrics do
  before do
    @config = reset!
  end

  def fixed_time
    @whence ||= Time.utc(2022, 7, 22, 22, 3, 0)
  end

  def create_known_metrics(time = fixed_time)
    smet = Sidekiq::Metrics::ExecutionTracker.new(@config)
    smet.track("critical", "App::SomeJob") { sleep 0.001 }
    smet.track("critical", "App::FooJob") { sleep 0.001 }
    assert_raises RuntimeError do
      smet.track("critical", "App::SomeJob") do
        raise "boom"
      end
    end
    smet.flush(time)
    smet.track("critical", "App::FooJob") { sleep 0.001 }
    smet.track("critical", "App::FooJob") { sleep 0.025 }
    smet.track("critical", "App::FooJob") { sleep 0.001 }
    smet.track("critical", "App::SomeJob") { sleep 0.001 }
    smet.flush(time - 60)
  end

  it "tracks metrics" do
    count = create_known_metrics
    assert_equal 4, count
  end

  describe "marx" do
    it "owns the means of production" do
      whence = Time.local(2022, 7, 17, 18, 43, 15)
      floor = whence.utc.iso8601.sub(":15", ":00")

      d = Sidekiq::Deploy.new
      d.mark!(at: whence, label: "cafed00d - some git summary line")
      d.mark!(at: whence)

      q = Sidekiq::Metrics::Query.new(now: whence)
      rs = q.for_job("FooJob")
      refute_nil rs.marks
      assert_equal 1, rs.marks.size
      assert_equal "cafed00d - some git summary line", rs.marks.first.label, rs.marks.inspect

      d = Sidekiq::Deploy.new
      rs = d.fetch(whence)
      refute_nil rs
      assert_equal 1, rs.size
      assert_equal "cafed00d - some git summary line", rs[floor]
    end
  end

  describe "histograms" do
    it "buckets a bunch of times" do
      h = Sidekiq::Metrics::Histogram.new("App::FooJob")
      assert_equal 0, h.sum
      h.record_time(10)
      h.record_time(46)
      h.record_time(47)
      h.record_time(48)
      h.record_time(300)
      h.record_time(301)
      h.record_time(302)
      h.record_time(300000000)
      assert_equal 8, h.sum
      key = @config.redis do |conn|
        h.persist(conn, fixed_time)
      end
      assert_equal 0, h.sum
      refute_nil key
      assert_equal "App::FooJob-22-22:3", key

      h = Sidekiq::Metrics::Histogram.new("App::FooJob")
      data = @config.redis { |c| h.fetch(c, fixed_time) }
      {0 => 1, 3 => 3, 7 => 3, 25 => 1}.each_pair do |idx, val|
        assert_equal val, data[idx]
      end
    end
  end

  describe "querying" do
    it "handles empty metrics" do
      q = Sidekiq::Metrics::Query.new(now: fixed_time)
      result = q.top_jobs
      assert_equal 60, result.buckets.size
      assert_equal([], result.job_results.keys)

      q = Sidekiq::Metrics::Query.new(now: fixed_time)
      result = q.for_job("DoesntExist")
      assert_equal 60, result.buckets.size
      assert_equal(["DoesntExist"], result.job_results.keys)
    end

    it "filters top job data" do
      create_known_metrics

      q = Sidekiq::Metrics::Query.new(now: fixed_time)
      result = q.top_jobs(class_filter: /some/i)
      assert_equal fixed_time - 59 * 60, result.starts_at
      assert_equal fixed_time, result.ends_at

      assert_equal 60, result.buckets.size
      assert_equal "21:04", result.buckets.first
      assert_equal "22:03", result.buckets.last

      assert_equal %w[App::SomeJob].sort, result.job_results.keys.sort
      job_result = result.job_results["App::SomeJob"]
      refute_nil job_result
    end

    it "fetches top job data" do
      create_known_metrics
      d = Sidekiq::Deploy.new
      d.mark!(at: fixed_time - 300, label: "cafed00d - some git summary line")

      q = Sidekiq::Metrics::Query.new(now: fixed_time)
      result = q.top_jobs
      assert_equal fixed_time - 59 * 60, result.starts_at
      assert_equal fixed_time, result.ends_at
      assert_equal 1, result.marks.size
      assert_equal "cafed00d - some git summary line", result.marks[0].label
      assert_equal "21:58", result.marks[0].bucket

      assert_equal 60, result.buckets.size
      assert_equal "21:04", result.buckets.first
      assert_equal "22:03", result.buckets.last

      assert_equal %w[App::SomeJob App::FooJob].sort, result.job_results.keys.sort
      job_result = result.job_results["App::SomeJob"]
      refute_nil job_result
      assert_equal %w[p f ms s].sort, job_result.series.keys.sort
      assert_equal %w[p f ms s].sort, job_result.totals.keys.sort
      assert_equal 2, job_result.series.dig("p", "22:03")
      assert_equal 3, job_result.totals["p"]
      # Execution time is not consistent, so these assertions are not exact
      assert job_result.total_avg("ms").between?(0.5, 2), job_result.total_avg("ms")
      assert job_result.series_avg("s")["22:03"].between?(0.0005, 0.002), job_result.series_avg("s")
    end

    it "fetches job-specific data" do
      create_known_metrics
      d = Sidekiq::Deploy.new
      d.mark!(at: fixed_time - 300, label: "cafed00d - some git summary line")

      q = Sidekiq::Metrics::Query.new(now: fixed_time)
      result = q.for_job("App::FooJob")
      assert_equal fixed_time - 59 * 60, result.starts_at
      assert_equal fixed_time, result.ends_at
      assert_equal 1, result.marks.size
      assert_equal "cafed00d - some git summary line", result.marks[0].label
      assert_equal "21:58", result.marks[0].bucket

      assert_equal 60, result.buckets.size
      assert_equal "21:04", result.buckets.first
      assert_equal "22:03", result.buckets.last

      # from create_known_data
      assert_equal %w[App::FooJob], result.job_results.keys
      job_result = result.job_results["App::FooJob"]
      refute_nil job_result
      assert_equal %w[p ms s].sort, job_result.series.keys.sort
      assert_equal %w[p ms s].sort, job_result.totals.keys.sort
      assert_equal 1, job_result.series.dig("p", "22:03")
      assert_equal 4, job_result.totals["p"]
      assert_equal 2, job_result.hist.dig("22:02", -1)
      assert_equal 1, job_result.hist.dig("22:02", -2)
    end
  end
end
