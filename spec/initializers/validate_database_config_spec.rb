# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validate database config' do
  include StubENV

  let(:rails_configuration) { Rails::Application::Configuration.new(Rails.root) }
  let(:ar_configurations) { ActiveRecord::DatabaseConfigurations.new(rails_configuration.database_configuration) }

  subject do
    load Rails.root.join('config/initializers/validate_database_config.rb')
  end

  before do
    # The `AS::ConfigurationFile` calls `read` in `def initialize`
    # thus we cannot use `expect_next_instance_of`
    # rubocop:disable RSpec/AnyInstanceOf
    expect_any_instance_of(ActiveSupport::ConfigurationFile)
      .to receive(:read).with(Rails.root.join('config/database.yml')).and_return(database_yml)
    # rubocop:enable RSpec/AnyInstanceOf

    allow(Rails.application).to receive(:config).and_return(rails_configuration)
    allow(ActiveRecord::Base).to receive(:configurations).and_return(ar_configurations)
  end

  shared_examples 'with SKIP_DATABASE_CONFIG_VALIDATION=true' do
    before do
      stub_env('SKIP_DATABASE_CONFIG_VALIDATION', 'true')
    end

    it 'does not raise exception' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when config/database.yml is valid' do
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
      EOS
    end

    it 'validates configuration without errors and warnings' do
      expect { subject }.not_to output.to_stderr
    end
  end

  context 'when config/database.yml is invalid' do
    context 'uses unknown connection name' do
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

            another:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error(/This installation of GitLab uses unsupported database names/)
      end

      it_behaves_like 'with SKIP_DATABASE_CONFIG_VALIDATION=true'
    end

    context 'uses replica configuration' do
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
              replica: true
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error(/with 'replica: true' parameter in/)
      end

      it_behaves_like 'with SKIP_DATABASE_CONFIG_VALIDATION=true'
    end

    context 'main is not a first entry' do
      let(:database_yml) do
        <<-EOS
          production:
            ci:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production_ci
              username: git
              password: "secure password"
              host: localhost
              replica: true

            main:
              adapter: postgresql
              encoding: unicode
              database: gitlabhq_production
              username: git
              password: "secure password"
              host: localhost
              replica: true
        EOS
      end

      it 'raises exception' do
        expect { subject }.to raise_error(/The `main:` database needs to be defined as a first configuration item/)
      end

      it_behaves_like 'with SKIP_DATABASE_CONFIG_VALIDATION=true'
    end
  end
end
