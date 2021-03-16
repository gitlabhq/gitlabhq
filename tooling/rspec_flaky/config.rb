# frozen_string_literal: true

module RspecFlaky
  class Config
    def self.generate_report?
      !!(ENV['FLAKY_RSPEC_GENERATE_REPORT'] =~ /1|true/)
    end

    def self.suite_flaky_examples_report_path
      ENV['SUITE_FLAKY_RSPEC_REPORT_PATH'] || rails_path("rspec_flaky/suite-report.json")
    end

    def self.flaky_examples_report_path
      ENV['FLAKY_RSPEC_REPORT_PATH'] || rails_path("rspec_flaky/report.json")
    end

    def self.new_flaky_examples_report_path
      ENV['NEW_FLAKY_RSPEC_REPORT_PATH'] || rails_path("rspec_flaky/new-report.json")
    end

    def self.rails_path(path)
      return path unless defined?(Rails)

      Rails.root.join(path)
    end
  end
end
