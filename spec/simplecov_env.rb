# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'simplecov-lcov'
require 'gitlab/utils/all'

module SimpleCovEnv
  extend self

  def start!
    return if !ENV.key?('SIMPLECOV') || ENV['SIMPLECOV'] == '0'
    return if SimpleCov.running

    configure_profile
    configure_job
    configure_formatter

    SimpleCov.start
  end

  def configure_formatter
    SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::CoberturaFormatter,
        SimpleCov::Formatter::LcovFormatter
      ]
    )
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

      add_filter '/bin/'
      add_filter 'db/fixtures/development/' # Matches EE files as well
      add_filter %r|db/migrate/\d{14}_init_schema\.rb\z| # Matches EE files as well
      add_filter '/gems/'
      add_filter '/vendor/'

      add_group 'Channels',     'app/channels' # Matches EE files as well
      add_group 'Components',   'app/components' # Matches EE files as well
      add_group 'Config',       %w[/config /ee/config]
      add_group 'Controllers',  'app/controllers' # Matches EE files as well
      add_group 'Elastic migrations', 'ee/elastic'
      add_group 'Enums',        'app/enums' # Matches EE files as well
      add_group 'Events',       'app/events' # Matches EE files as well
      add_group 'Experiments',  'app/experiments' # Matches EE files as well
      add_group 'Finders',      'app/finders' # Matches EE files as well
      add_group 'Fixtures',     'db/fixtures' # Matches EE files as well
      add_group 'GraphQL',      'app/graphql' # Matches EE files as well
      add_group 'Helpers',      'app/helpers' # Matches EE files as well
      add_group 'Mailers',      'app/mailers' # Matches EE files as well
      add_group 'Models',       'app/models' # Matches EE files as well
      add_group 'Policies',     'app/policies' # Matches EE files as well
      add_group 'Presenters',   'app/presenters' # Matches EE files as well
      add_group 'Replicators',  'app/replicators' # Matches EE files as well
      add_group 'Serializers',  'app/serializers' # Matches EE files as well
      add_group 'Services',     'app/services' # Matches EE files as well
      add_group 'Uploaders',    'app/uploaders' # Matches EE files as well
      add_group 'Validators',   'app/validators' # Matches EE files as well
      add_group 'Views',        'app/views' # Matches EE files as well
      add_group 'Workers',      'app/workers' # Matches EE files as well
      add_group 'Initializers', %w[config/initializers config/initializers_before_autoloader] # Matches EE files as well
      add_group 'Migrations',   %w[db/migrate db/optional_migrations db/post_migrate db/geo/migrate db/geo/post_migrate] # Matches EE files as well
      add_group 'Libraries',    %w[/lib /ee/lib]
      add_group 'Tooling',      %w[/haml_lint /rubocop /scripts /tooling]

      merge_timeout 365 * 24 * 3600
    end
  end
end
