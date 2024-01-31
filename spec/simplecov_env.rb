# frozen_string_literal: true

require_relative 'simplecov_env_core'
require 'gitlab/utils/all'

module SimpleCovEnv
  extend self
  extend SimpleCovEnvCore

  def start!
    return if !ENV.key?('SIMPLECOV') || ENV['SIMPLECOV'] == '0'
    return if SimpleCov.running

    configure_profile
    configure_job
    configure_formatter

    SimpleCov.start
  end

  def configure_job
    SimpleCov.configure do
      if ENV['CI_JOB_NAME']
        coverage_name = Gitlab::Utils.slugify("#{ENV['CI_JOB_NAME']}-#{ENV['CI_PROJECT_ID']}")
        coverage_dir "coverage/#{coverage_name}"
        command_name coverage_name
      end

      if ENV['CI']
        SimpleCov.at_exit do
          # In CI environment don't generate formatted reports
          # Only generate .resultset.json
          SimpleCov.result
        end
      end
    end
  end
end
