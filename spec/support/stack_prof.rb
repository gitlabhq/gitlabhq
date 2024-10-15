# frozen_string_literal: true

require 'stackprof'

# Applies stackprof instrumentation to a given rspec context
# Use as context "your context", :stackprof do
# or as context "your context", stackprof: { mode: wall, interval: 100000 } do
# to change arguments to stackprof.
#
# Results will be gzipped and placed in tmp/ if running locally, or rspec/ if running in CI, and can be viewed
# with any json-compatible flamegraph viewer, such as speedscope.

module Support
  module StackProf
    def self.start(example)
      puts "Starting stackprof"
      raise "Cannot nest stackprof calls!" if ::StackProf.running?

      ::StackProf.start(**stackprof_args_for(example))
    end

    def self.finish(example)
      raise "Stackprof was not running!" unless ::StackProf.running?

      ::StackProf.stop
      puts 'finishing stackprof'
      location = example.class.metadata[:location]
      # Turn a file path like ./spec/path/to/spec.rb:123 into spec_path_to_spec_123
      location_sanitized = location.gsub('./', '').tr('/', '_').gsub('.rb', '').tr(':', '_')

      out_filepath = if ENV['CI']
                       "rspec/stackprof_#{location_sanitized}-#{ENV['CI_JOB_NAME_SLUG']}.json.gz"
                     else
                       "tmp/stackprof_#{location_sanitized}.json.gz"
                     end

      start_time = ::Gitlab::Metrics::System.monotonic_time
      Zlib::GzipWriter.open(out_filepath) do |gz|
        gz.puts Gitlab::Json.generate(::StackProf.results)
      end
      end_time = ::Gitlab::Metrics::System.monotonic_time
      puts "Wrote stackprof dump to #{out_filepath} in #{(end_time - start_time).round(2)}s"
    end

    def self.stackprof_args_for(example)
      caller_config = example.class.metadata[:stackprof]
      default = {
        mode: :wall,
        interval: 10100, # in us, 99hz
        raw: true # Needed for flamegraphs
      }
      # If called as `:stackprof`, the value will be a literal `true`
      return default unless caller_config.is_a?(Hash)

      default.merge(caller_config)
    end
  end
end

RSpec.configure do |config|
  config.before(:all, :stackprof) do |example|
    Support::StackProf.start(example)
  end

  config.after(:all, :stackprof) do |example|
    Support::StackProf.finish(example)
  end
end
