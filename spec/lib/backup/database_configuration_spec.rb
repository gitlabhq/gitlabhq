# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::DatabaseConfiguration, :reestablished_active_record_base, feature_category: :backup_restore do
  using RSpec::Parameterized::TableSyntax

  let(:connection_name) { 'main' }

  subject(:config) { described_class.new(connection_name) }

  describe '#initialize' do
    it 'initializes with the provided connection_name' do
      expect_next_instance_of(described_class) do |config|
        expect(config.connection_name).to eq(connection_name)
      end

      config
    end
  end

  describe '#activerecord_configuration' do
    it 'returns a ActiveRecord::DatabaseConfigurations::HashConfig' do
      expect(config.activerecord_configuration).to be_a ActiveRecord::DatabaseConfigurations::HashConfig
    end
  end

  context 'with configuration override feature' do
    let(:application_config) do
      {
        adapter: 'postgresql',
        host: 'some_host',
        port: '5432'
      }
    end

    let(:active_record_key) { described_class::SUPPORTED_OVERRIDES.invert[pg_env] }

    before do
      allow(config).to receive(:original_activerecord_config).and_return(application_config)
    end

    shared_context 'with generic database with overridden values' do
      where(:env_variable, :overridden_value) do
        'GITLAB_BACKUP_PGHOST' | 'test.invalid.'
        'GITLAB_BACKUP_PGUSER' | 'some_user'
        'GITLAB_BACKUP_PGPORT' | '1543'
        'GITLAB_BACKUP_PGPASSWORD' | 'secret'
        'GITLAB_BACKUP_PGSSLMODE' | 'allow'
        'GITLAB_BACKUP_PGSSLKEY' | 'some_key'
        'GITLAB_BACKUP_PGSSLCERT' | '/path/to/cert'
        'GITLAB_BACKUP_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_BACKUP_PGSSLCRL' | '/path/to/crl'
        'GITLAB_BACKUP_PGSSLCOMPRESSION' | '1'
        'GITLAB_OVERRIDE_PGHOST' | 'test.invalid.'
        'GITLAB_OVERRIDE_PGUSER' | 'some_user'
        'GITLAB_OVERRIDE_PGPORT' | '1543'
        'GITLAB_OVERRIDE_PGPASSWORD' | 'secret'
        'GITLAB_OVERRIDE_PGSSLMODE' | 'allow'
        'GITLAB_OVERRIDE_PGSSLKEY' | 'some_key'
        'GITLAB_OVERRIDE_PGSSLCERT' | '/path/to/cert'
        'GITLAB_OVERRIDE_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_OVERRIDE_PGSSLCRL' | '/path/to/crl'
        'GITLAB_OVERRIDE_PGSSLCOMPRESSION' | '1'
      end
    end

    shared_context 'with generic database with overridden values using current database prefix' do
      where(:env_variable, :overridden_value) do
        'GITLAB_BACKUP_MAIN_PGHOST' | 'test.invalid.'
        'GITLAB_BACKUP_MAIN_PGUSER' | 'some_user'
        'GITLAB_BACKUP_MAIN_PGPORT' | '1543'
        'GITLAB_BACKUP_MAIN_PGPASSWORD' | 'secret'
        'GITLAB_BACKUP_MAIN_PGSSLMODE' | 'allow'
        'GITLAB_BACKUP_MAIN_PGSSLKEY' | 'some_key'
        'GITLAB_BACKUP_MAIN_PGSSLCERT' | '/path/to/cert'
        'GITLAB_BACKUP_MAIN_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_BACKUP_MAIN_PGSSLCRL' | '/path/to/crl'
        'GITLAB_BACKUP_MAIN_PGSSLCOMPRESSION' | '1'
        'GITLAB_OVERRIDE_MAIN_PGHOST' | 'test.invalid.'
        'GITLAB_OVERRIDE_MAIN_PGUSER' | 'some_user'
        'GITLAB_OVERRIDE_MAIN_PGPORT' | '1543'
        'GITLAB_OVERRIDE_MAIN_PGPASSWORD' | 'secret'
        'GITLAB_OVERRIDE_MAIN_PGSSLMODE' | 'allow'
        'GITLAB_OVERRIDE_MAIN_PGSSLKEY' | 'some_key'
        'GITLAB_OVERRIDE_MAIN_PGSSLCERT' | '/path/to/cert'
        'GITLAB_OVERRIDE_MAIN_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_OVERRIDE_MAIN_PGSSLCRL' | '/path/to/crl'
        'GITLAB_OVERRIDE_MAIN_PGSSLCOMPRESSION' | '1'
      end
    end

    shared_context 'with generic database with overridden values for a different database prefix' do
      where(:env_variable, :overridden_value) do
        'GITLAB_BACKUP_CI_PGHOST' | 'test.invalid.'
        'GITLAB_BACKUP_CI_PGUSER' | 'some_user'
        'GITLAB_BACKUP_CI_PGPORT' | '1543'
        'GITLAB_BACKUP_CI_PGPASSWORD' | 'secret'
        'GITLAB_BACKUP_CI_PGSSLMODE' | 'allow'
        'GITLAB_BACKUP_CI_PGSSLKEY' | 'some_key'
        'GITLAB_BACKUP_CI_PGSSLCERT' | '/path/to/cert'
        'GITLAB_BACKUP_CI_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_BACKUP_CI_PGSSLCRL' | '/path/to/crl'
        'GITLAB_BACKUP_CI_PGSSLCOMPRESSION' | '1'
        'GITLAB_OVERRIDE_CI_PGHOST' | 'test.invalid.'
        'GITLAB_OVERRIDE_CI_PGUSER' | 'some_user'
        'GITLAB_OVERRIDE_CI_PGPORT' | '1543'
        'GITLAB_OVERRIDE_CI_PGPASSWORD' | 'secret'
        'GITLAB_OVERRIDE_CI_PGSSLMODE' | 'allow'
        'GITLAB_OVERRIDE_CI_PGSSLKEY' | 'some_key'
        'GITLAB_OVERRIDE_CI_PGSSLCERT' | '/path/to/cert'
        'GITLAB_OVERRIDE_CI_PGSSLROOTCERT' | '/path/to/root/cert'
        'GITLAB_OVERRIDE_CI_PGSSLCRL' | '/path/to/crl'
        'GITLAB_OVERRIDE_CI_PGSSLCOMPRESSION' | '1'
      end
    end

    describe('#pg_env_variables') do
      context 'with provided ENV variables' do
        before do
          stub_env(env_variable, overridden_value)
        end

        context 'when generic database configuration is overridden' do
          include_context "with generic database with overridden values"

          with_them do
            let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_(\w+)/, 2] }

            it 'PostgreSQL ENV overrides application configuration' do
              expect(config.pg_env_variables).to include({ pg_env => overridden_value })
            end
          end
        end

        context 'when specific database configuration is overridden' do
          context 'and environment variables are for the current database name' do
            include_context 'with generic database with overridden values using current database prefix'

            with_them do
              let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_MAIN_(\w+)/, 2] }

              it 'PostgreSQL ENV overrides application configuration' do
                expect(config.pg_env_variables).to include({ pg_env => overridden_value })
              end
            end
          end

          context 'and environment variables are for another database' do
            include_context 'with generic database with overridden values for a different database prefix'

            with_them do
              let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_CI_(\w+)/, 1] }

              it 'PostgreSQL ENV is expected to equal application configuration' do
                expect(config.pg_env_variables).to eq(
                  {
                    'PGHOST' => application_config[:host],
                    'PGPORT' => application_config[:port]
                  }
                )
              end
            end
          end
        end
      end

      context 'when both GITLAB_BACKUP_PGUSER and GITLAB_BACKUP_MAIN_PGUSER variable are present' do
        it 'prefers more specific GITLAB_BACKUP_MAIN_PGUSER' do
          stub_env('GITLAB_BACKUP_PGUSER', 'generic_user')
          stub_env('GITLAB_BACKUP_MAIN_PGUSER', 'specific_user')

          expect(config.pg_env_variables['PGUSER']).to eq('specific_user')
        end
      end
    end

    describe('#activerecord_variables') do
      context 'with provided ENV variables' do
        before do
          stub_env(env_variable, overridden_value)
        end

        context 'when generic database configuration is overridden' do
          include_context "with generic database with overridden values"

          with_them do
            let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_(\w+)/, 2] }

            it 'ActiveRecord backup configuration overrides application configuration' do
              expect(config.activerecord_variables).to eq(
                application_config.merge(active_record_key => overridden_value)
              )
            end
          end
        end

        context 'when specific database configuration is overridden' do
          context 'and environment variables are for the current database name' do
            include_context 'with generic database with overridden values using current database prefix'

            with_them do
              let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_MAIN_(\w+)/, 2] }

              it 'ActiveRecord backup configuration overrides application configuration' do
                expect(config.activerecord_variables).to eq(
                  application_config.merge(active_record_key => overridden_value)
                )
              end
            end
          end

          context 'and environment variables are for another database' do
            include_context 'with generic database with overridden values for a different database prefix'

            with_them do
              let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_CI_(\w+)/, 1] }

              it 'ActiveRecord backup configuration is expected to equal application configuration' do
                expect(config.activerecord_variables).to eq(application_config)
              end
            end
          end
        end
      end

      context 'when both GITLAB_BACKUP_PGUSER and GITLAB_BACKUP_MAIN_PGUSER variable are present' do
        with_them do
          it 'prefers more specific GITLAB_BACKUP_MAIN_PGUSER' do
            stub_env('GITLAB_BACKUP_PGUSER', 'generic_user')
            stub_env('GITLAB_BACKUP_MAIN_PGUSER', 'specific_user')

            expect(config.activerecord_variables[:username]).to eq('specific_user')
          end
        end
      end
    end
  end
end
