# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'simplecov-lcov'

module SimpleCovEnvCore
  extend self

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

  def configure_profile
    SimpleCov.configure do
      load_profile 'test_frameworks'

      add_filter %r{^/(ee/)?(bin|gems|vendor)}
      add_filter %r{^/(ee/)?db/fixtures/development}
      add_filter %r{^/(ee/)?db/migrate/\d{14}_init_schema\.rb\z}

      add_group 'Channels',           %r{^/(ee/)?app/channels}
      add_group 'Components',         %r{^/(ee/)?app/components}
      add_group 'Config',             %r{^/(ee/)?config}
      add_group 'Controllers',        %r{^/(ee/)?app/controllers}
      add_group 'Elastic migrations', %r{^/(ee/)?elastic}
      add_group 'Enums',              %r{^/(ee/)?app/enums}
      add_group 'Events',             %r{^/(ee/)?app/events}
      add_group 'Experiments',        %r{^/(ee/)?app/experiments}
      add_group 'Finders',            %r{^/(ee/)?app/finders}
      add_group 'Fixtures',           %r{^/(ee/)?db/fixtures}
      add_group 'GraphQL',            %r{^/(ee/)?app/graphql}
      add_group 'Helpers',            %r{^/(ee/)?app/helpers}
      add_group 'Libraries',          %r{^/(ee/)?lib}
      add_group 'Mailers',            %r{^/(ee/)?app/mailers}
      add_group 'Metrics server',     %r{^/(ee/)?metrics_server}
      add_group 'Migrations',         %r{^/(ee/)?db/(geo/)?(migrate|optional_migrations|post_migrate)}
      add_group 'Models',             %r{^/(ee/)?app/models}
      add_group 'Policies',           %r{^/(ee/)?app/policies}
      add_group 'Presenters',         %r{^/(ee/)?app/presenters}
      add_group 'Replicators',        %r{^/(ee/)?app/replicators}
      add_group 'Seeds',              %r{^/(ee/)?db/seeds}
      add_group 'Serializers',        %r{^/(ee/)?app/serializers}
      add_group 'Services',           %r{^/(ee/)?app/services}
      add_group 'Sidekiq cluster',    %r{^/(ee/)?sidekiq_cluster}
      add_group 'Tooling',            %r{^/(ee/)?(danger|haml_lint|rubocop|scripts|tooling)}
      add_group 'Uploaders',          %r{^/(ee/)?app/uploaders}
      add_group 'Validators',         %r{^/(ee/)?app/validators}
      add_group 'Views',              %r{^/(ee/)?app/views}
      add_group 'Workers',            %r{^/(ee/)?app/workers}

      merge_timeout 365 * 24 * 3600
    end
  end
end
