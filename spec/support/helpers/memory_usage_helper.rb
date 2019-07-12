# frozen_string_literal: true

module MemoryUsageHelper
  extend ActiveSupport::Concern

  def gather_memory_data(csv_path)
    write_csv_entry(csv_path,
      {
        example_group_path: TestEnv.topmost_example_group[:location],
        example_group_description: TestEnv.topmost_example_group[:description],
        time: Time.current,
        job_name: ENV['CI_JOB_NAME']
      }.merge(get_memory_usage))
  end

  def write_csv_entry(path, entry)
    CSV.open(path, "a", headers: entry.keys, write_headers: !File.exist?(path)) do |file|
      file << entry.values
    end
  end

  def get_memory_usage
    output, status = Gitlab::Popen.popen(%w(free -m))
    abort "`free -m` return code is #{status}: #{output}" unless status.zero?

    result = output.split("\n")[1].split(" ")[1..-1]
    attrs = %i(m_total m_used m_free m_shared m_buffers_cache m_available).freeze

    attrs.zip(result).to_h
  end

  included do |config|
    config.after(:all) do
      gather_memory_data(ENV['MEMORY_TEST_PATH']) if ENV['MEMORY_TEST_PATH']
    end
  end
end
