# frozen_string_literal: true

# Stress test: Sidekiq heartbeat starvation under Ruby 3.3 GVL contention
#
# Ruby 3.3 changed thread scheduling for the M:N thread model (Ruby Bug #20816),
# increasing context-switching overhead under GVL contention. With high Sidekiq
# concurrency, the heartbeat thread can be starved long enough for its Redis key
# to expire, silently deregistering the process.
#
# This script measures heartbeat behaviour under sustained GVL contention and
# compares two configurations:
#
#   Scenario A — original:  BEAT_PAUSE=10s, TTL=60s,  thread priority=0
#   Scenario B — fixed:     BEAT_PAUSE=10s, TTL=120s, thread priority=3
#
# What we measure:
#   - Beat interval jitter: actual beat-to-beat wall time vs configured interval.
#     Higher jitter = heartbeat thread is being delayed by GVL contention.
#   - Minimum TTL observed: how close to zero the Redis key gets.
#     If it reaches 0 the process silently deregisters.
#   - Safety headroom: how many missed beats the configuration can absorb before
#     deregistration. This is the key theoretical improvement.
#
# NOTE: Reproducing actual heartbeat starvation requires sustained production-
# level load (20+ threads under heavy syscall pressure). On a dev machine both
# scenarios will likely pass — the value of this script is in measuring the
# relative improvement and providing a reproducible harness for affected users.
#
# Usage:
#   ruby test/stress/heartbeat_starvation_test.rb
#
# Requires Redis on localhost:6379 (or set REDIS_URL env var).
# Set CONCURRENCY env var to override the default of 20.
#
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/594030
# See: https://bugs.ruby-lang.org/issues/20816

$LOAD_PATH.unshift File.join(__dir__, "../../lib")

require "logger"
require "sidekiq"
require "sidekiq/launcher"

CONCURRENCY = (ENV["CONCURRENCY"] || 20).to_i
SCENARIO_SECS = (ENV["SCENARIO_SECS"] || 60).to_i
SAMPLE_INTERVAL = 1.0
JOBS_PER_WORKER = 500

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

# A job that performs rapid fast syscalls in a tight loop — the workload from
# Ruby Bug #20816 that produces GVL contention between threads on Ruby 3.3.
# Thread.pass every 1000 iterations prevents total GVL monopolisation so that
# the heartbeat thread and monitor can still make forward progress.
class HeartbeatStressJob
  include Sidekiq::Job

  sidekiq_options queue: "stress"

  def perform(iterations)
    iterations.times.with_index do |_, i|
      File.mtime(__FILE__)
      Thread.pass if (i % 1000).zero?
    end
  end
end

NULL_LOGGER = Logger.new(File::NULL)

def build_config
  cfg = Sidekiq::Config.new
  cfg.logger = NULL_LOGGER
  cfg.redis = { url: REDIS_URL }
  cfg.default_capsule.concurrency = CONCURRENCY
  cfg.queues = ["stress"]
  Sidekiq.instance_variable_set(:@config, cfg)
  cfg
end

def flush_redis(cfg)
  cfg.redis { |c| c.call("FLUSHDB") }
end

def enqueue_jobs(cfg)
  Sidekiq::Client.new(config: cfg).push_bulk(
    "class" => HeartbeatStressJob.to_s,
    "queue" => "stress",
    "args" => Array.new(CONCURRENCY * JOBS_PER_WORKER) { [10_000] }
  )
end

def build_launcher(cfg, beat_pause:, ttl:, priority:, beat_times:)
  klass = Class.new(Sidekiq::Launcher) do
    define_method(:start_heartbeat) do
      Thread.current.priority = priority
      loop do
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        beat
        beat_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
        sleep beat_pause
        # Jitter = how much longer than (beat_pause + beat_duration) the full
        # cycle took. Positive means the thread was delayed getting scheduled.
        total = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
        beat_times << (total - beat_pause - beat_duration)
      end
    end

    define_method(:❤) do
      key = identity
      begin
        curstate = Sidekiq::Processor::WORK_STATE.dup
        curstate.transform_values! { |val| Sidekiq.dump_json(val) }

        redis do |conn|
          work_key = "#{key}:work"
          conn.multi do |transaction|
            transaction.unlink(work_key)

            if curstate.size > 0
              transaction.hset(work_key, curstate)
              transaction.expire(work_key, ttl)
            end
          end
        end

        rtt = check_rtt
        kb = memory_usage(::Process.pid)

        _, exists, _, _, signal = redis do |conn|
          conn.multi do |transaction|
            transaction.sadd("processes", [key])
            transaction.exists(key)
            transaction.hset(key, "info", to_json,
              "busy", curstate.size,
              "beat", Time.now.to_f,
              "rtt_us", rtt,
              "quiet", @done.to_s,
              "rss", kb)
            transaction.expire(key, ttl)
            transaction.rpop("#{key}-signals")
          end
        end

        fire_event(:heartbeat) unless exists > 0
        fire_event(:beat, oneshot: false)
        ::Process.kill(signal, ::Process.pid) if signal && !@embedded
      rescue StandardError => e
        logger.error("heartbeat: #{e}")
      end
    end
  end

  klass.new(cfg)
end

Sample = Struct.new(:elapsed, :ttl_ms)

def run_scenario(label, beat_pause:, ttl:, priority:)
  $stdout.puts "\n--- #{label}: beat=#{beat_pause}s, ttl=#{ttl}s, priority=#{priority} ---"
  $stdout.flush

  cfg = build_config
  flush_redis(cfg)
  enqueue_jobs(cfg)
  $stdout.printf("  Enqueued %d jobs, starting %d workers...\n",
    CONCURRENCY * JOBS_PER_WORKER, CONCURRENCY)
  $stdout.flush

  beat_times = []
  launcher = build_launcher(cfg, beat_pause: beat_pause, ttl: ttl,
    priority: priority, beat_times: beat_times)
  launcher.run(async_beat: true)

  sleep 3

  identity = launcher.identity
  samples = []
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  $stdout.print "  Sampling"
  $stdout.flush

  SCENARIO_SECS.times do |i|
    sleep SAMPLE_INTERVAL
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    ttl_ms = cfg.redis { |c| c.call("PTTL", identity) }
    samples << Sample.new(elapsed.round(2), ttl_ms)
    $stdout.print "." if (i % 10).zero?
    $stdout.flush
  end

  $stdout.puts " done"
  $stdout.flush

  launcher.stop

  { samples: samples, beat_times: beat_times, ttl: ttl, beat_pause: beat_pause }
end

def analyze(label, data)
  samples = data[:samples]
  beat_times = data[:beat_times]
  ttl_sec = data[:ttl]
  beat_pause = data[:beat_pause]
  ttl_ms_max = ttl_sec * 1000

  # Skip warmup period (2 × beat_pause) to let the heartbeat thread fire at
  # least once before we start measuring TTL health.
  warmup = beat_pause * 2
  valid = samples.select { |s| s.ttl_ms > 0 && s.elapsed > warmup }
  valid = samples.select { |s| s.ttl_ms > 0 } if valid.empty?

  min_ttl = valid.map(&:ttl_ms).min.to_f
  mean_ttl = valid.empty? ? 0 : valid.sum(&:ttl_ms).to_f / valid.size
  min_pct = (min_ttl / ttl_ms_max * 100).round(1)
  mean_pct = (mean_ttl / ttl_ms_max * 100).round(1)
  refreshes = 0
  samples.each_cons(2) { |a, b| refreshes += 1 if b.ttl_ms > a.ttl_ms }

  # beat_times already contains pure scheduling delay (total - beat_pause - beat_duration)
  jitter_avg = beat_times.empty? ? 0 : beat_times.sum.to_f / beat_times.size
  jitter_max = beat_times.empty? ? 0 : beat_times.max

  # Theoretical safety: how many consecutive missed beats before deregistration?
  missed_beats_capacity = (ttl_sec.to_f / beat_pause).floor

  # Pass if min TTL stayed above beat_pause * 3 (survived 3+ missed beats headroom)
  threshold = beat_pause * 3 * 1000
  passed = min_ttl >= threshold

  $stdout.puts ""
  $stdout.puts "  Results for #{label}:"
  $stdout.printf("  %-32s %d\n", "TTL samples:", valid.size)
  $stdout.printf("  %-32s %.1fs (%s%%)\n", "Min TTL:", min_ttl / 1000, min_pct)
  $stdout.printf("  %-32s %.1fs (%s%%)\n", "Mean TTL:", mean_ttl / 1000, mean_pct)
  $stdout.printf("  %-32s %d\n", "TTL refreshes observed:", refreshes)
  $stdout.printf("  %-32s %d\n", "Beat executions:", beat_times.size)

  unless beat_times.empty?
    $stdout.printf("  %-32s %+.4fs (avg),  %+.4fs (max)\n",
      "Scheduling delay (jitter):", jitter_avg, jitter_max)
  end

  $stdout.printf("  %-32s %d (TTL ÷ beat_pause)\n",
    "Missed beat capacity:", missed_beats_capacity)
  $stdout.printf("  %-32s %.1fs (beat_pause × 3)\n",
    "Pass threshold:", threshold / 1000.0)
  $stdout.printf("  %-32s %s\n", "Result:",
    passed ? "PASS ✓" : "FAIL ✗  (min TTL dropped below threshold)")

  { passed: passed, min_ttl: min_ttl, mean_ttl: mean_ttl, min_pct: min_pct,
    mean_pct: mean_pct, jitter_avg: jitter_avg, jitter_max: jitter_max,
    refreshes: refreshes, beat_count: beat_times.size,
    missed_beat_capacity: missed_beats_capacity }
end

# ── Main ──────────────────────────────────────────────────────────────────────

$stdout.puts "=" * 62
$stdout.puts "Sidekiq Heartbeat Starvation Stress Test"
$stdout.puts "=" * 62
$stdout.puts "Ruby:        #{RUBY_VERSION}"
$stdout.puts "Sidekiq:     #{Sidekiq::VERSION}"
$stdout.puts "Concurrency: #{CONCURRENCY} workers"
$stdout.puts "Duration:    #{SCENARIO_SECS}s per scenario"
$stdout.puts "Redis:       #{REDIS_URL}"
$stdout.puts ""
$stdout.puts "Workers call File.mtime in a tight loop to generate GVL"
$stdout.puts "contention (per Ruby Bug #20816 reproduction pattern)."
$stdout.puts ""
$stdout.flush

data_a = run_scenario("Scenario A (original)", beat_pause: 10, ttl: 60, priority: 0)
data_b = run_scenario("Scenario B (fixed)", beat_pause: 10, ttl: 120, priority: 3)

result_a = analyze("Scenario A (original)", data_a)
result_b = analyze("Scenario B (fixed)", data_b)

$stdout.puts ""
$stdout.puts "=" * 62
$stdout.puts "Comparison"
$stdout.puts "=" * 62
$stdout.printf("  %-34s %-16s %-16s\n", "",
  "A (original)", "B (fixed)")
$stdout.printf("  %-34s %-16s %-16s\n", "BEAT_PAUSE / TTL:",
  "10s / 60s", "10s / 120s")
$stdout.printf("  %-34s %-16s %-16s\n", "Thread priority:",
  "0 (default)", "3 (elevated)")
$stdout.printf("  %-34s %-16s %-16s\n", "Missed beat capacity:",
  result_a[:missed_beat_capacity].to_s,
  result_b[:missed_beat_capacity].to_s)
$stdout.printf("  %-34s %-16s %-16s\n", "Min TTL observed:",
  "#{(result_a[:min_ttl] / 1000).round(1)}s (#{result_a[:min_pct]}%)",
  "#{(result_b[:min_ttl] / 1000).round(1)}s (#{result_b[:min_pct]}%)")
$stdout.printf("  %-34s %-16s %-16s\n", "Mean TTL:",
  "#{(result_a[:mean_ttl] / 1000).round(1)}s (#{result_a[:mean_pct]}%)",
  "#{(result_b[:mean_ttl] / 1000).round(1)}s (#{result_b[:mean_pct]}%)")
$stdout.printf("  %-34s %-16s %-16s\n", "Scheduling delay (avg / max):",
  format("%.4fs / %.4fs", result_a[:jitter_avg], result_a[:jitter_max]),
  format("%.4fs / %.4fs", result_b[:jitter_avg], result_b[:jitter_max]))
$stdout.printf("  %-34s %-16s %-16s\n", "Result:",
  result_a[:passed] ? "PASS ✓" : "FAIL ✗",
  result_b[:passed] ? "PASS ✓" : "FAIL ✗")
$stdout.puts ""

improvement = result_b[:missed_beat_capacity].to_f / result_a[:missed_beat_capacity]
$stdout.puts "  Theoretical improvement: #{improvement.round(1)}× missed beat capacity"
$stdout.puts "  before deregistration (#{result_a[:missed_beat_capacity]} → #{result_b[:missed_beat_capacity]} beats)."
$stdout.puts ""

if !result_a[:passed] && result_b[:passed]
  $stdout.puts "  ✓ Fix is effective: original failed, fixed passed."
elsif result_a[:passed] && result_b[:passed]
  $stdout.puts "  ✓ Both passed on this machine. The improvement is primarily"
  $stdout.puts "    theoretical (#{improvement.round(1)}× missed beat capacity) and is most"
  $stdout.puts "    impactful on affected systems running Ruby 3.3 under high load."
  $stdout.puts "    Confirm with jitter measurements on a production-load instance."
elsif !result_a[:passed] && !result_b[:passed]
  $stdout.puts "  ✗ Both scenarios failed. Consider increasing TTL further."
end

$stdout.puts "=" * 62

exit(result_b[:passed] ? 0 : 1)
