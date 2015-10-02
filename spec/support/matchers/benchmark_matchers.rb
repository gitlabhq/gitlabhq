module BenchmarkMatchers
  extend RSpec::Matchers::DSL

  matcher :iterate_per_second do |min_iterations|
    supports_block_expectations

    match do |block|
      @max_stddev ||= 30

      @entry = benchmark(&block)

      expect(@entry.ips).to be >= min_iterations
      expect(@entry.stddev_percentage).to be <= @max_stddev
    end

    chain :with_maximum_stddev do |value|
      @max_stddev = value
    end

    description do
      "run at least #{min_iterations} iterations per second"
    end

    failure_message do
      ips    = @entry.ips.round(2)
      stddev = @entry.stddev_percentage.round(2)

      "expected at least #{min_iterations} iterations per second " \
        "with a maximum stddev of #{@max_stddev}%, instead of " \
        "#{ips} iterations per second with a stddev of #{stddev}%"
    end
  end

  # Benchmarks the given block and returns a Benchmark::IPS::Report::Entry.
  def benchmark(&block)
    report = Benchmark.ips(quiet: true) do |bench|
      bench.report(&block)
    end

    report.entries[0]
  end
end
