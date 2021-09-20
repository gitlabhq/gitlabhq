# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::LegacyDatabaseConfig do
  it 'module is included' do
    expect(Rails::Application::Configuration).to include(described_class)
  end

  describe 'config/database.yml' do
    let(:configuration) { Rails::Application::Configuration.new(Rails.root) }

    before do
      # The `AS::ConfigurationFile` calls `read` in `def initialize`
      # thus we cannot use `expect_next_instance_of`
      # rubocop:disable RSpec/AnyInstanceOf
      expect_any_instance_of(ActiveSupport::ConfigurationFile)
        .to receive(:read).with(Rails.root.join('config/database.yml')).and_return(database_yml)
      # rubocop:enable RSpec/AnyInstanceOf
    end

    shared_examples 'hash containing main: connection name' do
      it 'returns a hash containing only main:' do
        database_configuration = configuration.database_configuration

        expect(database_configuration).to match(
          "production" => { "main" => a_hash_including("adapter") },
          "development" => { "main" => a_hash_including("adapter" => "postgresql") },
          "test" => { "main" => a_hash_including("adapter" => "postgresql") }
        )
      end
    end

    context 'when a new syntax is used' do
      let(:database_yml) do
        <<-EOS
          production:
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost

          development:
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_development
              username: postgres
              password: "secure password"
              host: localhost
              variables:
                statement_timeout: 15s

          test: &test
            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_test
              username: postgres
              password:
              host: localhost
              prepared_statements: false
              variables:
                statement_timeout: 15s
        EOS
      end

      include_examples 'hash containing main: connection name'

      it 'configuration is not legacy one' do
        configuration.database_configuration

        expect(configuration.uses_legacy_database_config).to eq(false)
      end
    end

    context 'when a legacy syntax is used' do
      let(:database_yml) do
        <<-EOS
          production:
            adapter: postgresql
            encoding: unicode
            database: gitlabhq_production
            username: git
            password: "secure password"
            host: localhost

          development:
            adapter: postgresql
            encoding: unicode
            database: gitlabhq_development
            username: postgres
            password: "secure password"
            host: localhost
            variables:
              statement_timeout: 15s

          test: &test
            adapter: postgresql
            encoding: unicode
            database: gitlabhq_test
            username: postgres
            password:
            host: localhost
            prepared_statements: false
            variables:
              statement_timeout: 15s
        EOS
      end

      include_examples 'hash containing main: connection name'

      it 'configuration is legacy' do
        configuration.database_configuration

        expect(configuration.uses_legacy_database_config).to eq(true)
      end
    end
  end
end
