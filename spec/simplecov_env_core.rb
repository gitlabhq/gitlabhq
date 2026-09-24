# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'simplecov-lcov'

module SimpleCovEnvCore
  extend self

  def configure_formatter
    SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(formatters)
  end

  def configure_profile
    SimpleCov.configure do
      enable_coverage :branch

      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194688#note_2595596467
      skip %r{^/(ee/|jh/)?spec/}

      skip %r{^/(ee/)?(bin|gems|vendor)}
      skip %r{^/(ee/)?db/fixtures/development}
      skip %r{^/(ee/)?db/migrate/\d{14}_init_schema\.rb\z}

      group 'Channels',           %r{^/(ee/)?app/channels}
      group 'Components',         %r{^/(ee/)?app/components}
      group 'Config',             %r{^/(ee/)?config}
      group 'Controllers',        %r{^/(ee/)?app/controllers}
      group 'Elastic migrations', %r{^/(ee/)?elastic}
      group 'Enums',              %r{^/(ee/)?app/enums}
      group 'Events',             %r{^/(ee/)?app/events}
      group 'Experiments',        %r{^/(ee/)?app/experiments}
      group 'Finders',            %r{^/(ee/)?app/finders}
      group 'Fixtures',           %r{^/(ee/)?db/fixtures}
      group 'GraphQL',            %r{^/(ee/)?app/graphql}
      group 'Helpers',            %r{^/(ee/)?app/helpers}
      group 'Libraries',          %r{^/(ee/)?lib}
      group 'Mailers',            %r{^/(ee/)?app/mailers}
      group 'Metrics server',     %r{^/(ee/)?metrics_server}
      group 'Migrations',         %r{^/(ee/)?db/(geo/)?(migrate|optional_migrations|post_migrate)}
      group 'Models',             %r{^/(ee/)?app/models}
      group 'Policies',           %r{^/(ee/)?app/policies}
      group 'Presenters',         %r{^/(ee/)?app/presenters}
      group 'Replicators',        %r{^/(ee/)?app/replicators}
      group 'Seeds',              %r{^/(ee/)?db/seeds}
      group 'Serializers',        %r{^/(ee/)?app/serializers}
      group 'Services',           %r{^/(ee/)?app/services}
      group 'Sidekiq cluster',    %r{^/(ee/)?sidekiq_cluster}
      group 'Tooling',            %r{^/(ee/)?(danger|haml_lint|rubocop|scripts|tooling)}
      group 'Uploaders',          %r{^/(ee/)?app/uploaders}
      group 'Validators',         %r{^/(ee/)?app/validators}
      group 'Views',              %r{^/(ee/)?app/views}
      group 'Workers',            %r{^/(ee/)?app/workers}

      merge_timeout 365 * 24 * 3600
    end
  end

  private

  def formatters
    formatters = [
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::CoberturaFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]

    # Skip HTMLFormatter in MRs for performance.
    is_merge_request_ci = ENV['CI_PIPELINE_SOURCE'] == 'merge_request_event'
    formatters << SimpleCov::Formatter::HTMLFormatter unless is_merge_request_ci

    formatters
  end
end
