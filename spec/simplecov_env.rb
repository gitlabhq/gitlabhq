# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require_relative '../lib/gitlab/utils'

module SimpleCovEnv
  extend self

  def start!
    return unless ENV['SIMPLECOV']

    configure_profile
    configure_job
    configure_formatter

    SimpleCov.start
  end

  def configure_formatter
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter
    ])
  end

  def configure_job
    SimpleCov.configure do
      if ENV['CI_JOB_NAME']
        job_name = Gitlab::Utils.slugify(ENV['CI_JOB_NAME'])
        coverage_dir "coverage/#{job_name}"
        command_name job_name
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
      track_files '{app,config/initializers,config/initializers_before_autoloader,db/post_migrate,haml_lint,lib,rubocop,tooling}/**/*.rb'

      add_filter '/vendor/ruby/'
      add_filter '/app/controllers/sherlock/'
      add_filter '/bin/'
      add_filter 'db/fixtures/' # Matches EE files as well
      add_filter '/lib/gitlab/sidekiq_middleware/'
      add_filter '/lib/system_check/'

      add_group 'Channels',     'app/channels' # Matches EE files as well
      add_group 'Controllers',  'app/controllers' # Matches EE files as well
      add_group 'Finders',      'app/finders' # Matches EE files as well
      add_group 'GraphQL',      'app/graphql' # Matches EE files as well
      add_group 'Helpers',      'app/helpers' # Matches EE files as well
      add_group 'Mailers',      'app/mailers' # Matches EE files as well
      add_group 'Models',       'app/models' # Matches EE files as well
      add_group 'Policies',     'app/policies' # Matches EE files as well
      add_group 'Presenters',   'app/presenters' # Matches EE files as well
      add_group 'Serializers',  'app/serializers' # Matches EE files as well
      add_group 'Services',     'app/services' # Matches EE files as well
      add_group 'Uploaders',    'app/uploaders' # Matches EE files as well
      add_group 'Validators',   'app/validators' # Matches EE files as well
      add_group 'Workers',      %w[app/jobs app/workers] # Matches EE files as well
      add_group 'Initializers', %w[config/initializers config/initializers_before_autoloader] # Matches EE files as well
      add_group 'Migrations',   %w[db/migrate db/optional_migrations db/post_migrate] # Matches EE files as well
      add_group 'Libraries',    %w[/lib /ee/lib]
      add_group 'Tooling',      %w[/haml_lint /rubocop /tooling]

      merge_timeout 365 * 24 * 3600
    end
  end
end
