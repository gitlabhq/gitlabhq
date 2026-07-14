# frozen_string_literal: true

module Tooling
  # Announces to the user that there is a better way to run migrations
  # once the application exits (using at_exit).
  #
  # This is used in config/environments/development.rb and only runs in development environment when
  # the user runs db:migrate tasks directly with a Rake or Rails command.
  module RakeAnnouncer
    TIP_PREFIX = Rainbow("Pro tip").blue.freeze
    MIGRATION_SCRIPT = Rainbow('scripts/database/migrate.rb').yellow.freeze

    def self.should_run?
      return false if ENV.key?('CI')
      return false unless Rails.env.development?

      args.any? { |arg| arg.start_with?('db:migrate:') }
    end

    def self.args
      return Rake.application.top_level_tasks if Process.argv0.include?('rails')

      ARGV
    end

    def self.run
      return unless should_run?

      at_exit do
        puts
        puts "#{TIP_PREFIX}: try out #{MIGRATION_SCRIPT} for better migration management."
      end
    end
  end
end
