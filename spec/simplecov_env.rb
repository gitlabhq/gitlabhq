require 'simplecov'
require 'active_support/core_ext/numeric/time'

module SimpleCovEnv
  extend self

  def start!
    return unless ENV['SIMPLECOV']

    configure_profile
    configure_job

    SimpleCov.start
  end

  def configure_job
    SimpleCov.configure do
      if ENV['CI_JOB_NAME']
        coverage_dir "coverage/#{ENV['CI_JOB_NAME']}"
        command_name ENV['CI_JOB_NAME']
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

  def configure_profile
    SimpleCov.configure do
      load_profile 'test_frameworks'
      track_files '{app,lib}/**/*.rb'

      add_filter '/vendor/ruby/'
      add_filter 'app/controllers/sherlock/'
      add_filter 'config/initializers/'
      add_filter 'db/fixtures/'
      add_filter 'lib/gitlab/sidekiq_middleware/'
      add_filter 'lib/system_check/'

      add_group 'Controllers', 'app/controllers'
      add_group 'Finders',     'app/finders'
      add_group 'Helpers',     'app/helpers'
      add_group 'Libraries',   'lib'
      add_group 'Mailers',     'app/mailers'
      add_group 'Models',      'app/models'
      add_group 'Policies',    'app/policies'
      add_group 'Presenters',  'app/presenters'
      add_group 'Serializers', 'app/serializers'
      add_group 'Services',    'app/services'
      add_group 'Uploaders',   'app/uploaders'
      add_group 'Validators',  'app/validators'
      add_group 'Workers',     %w(app/jobs app/workers)

      merge_timeout 365.days
    end
  end
end
