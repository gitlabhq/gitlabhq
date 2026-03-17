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

  describe 'custom_config option' do
    context 'when custom_config is nil' do
      subject(:config) { described_class.new(connection_name, custom_config: nil) }

      it 'uses standard database.yml lookup' do
        expect(config.connection_name).to eq('main')
      end

      it 'returns activerecord configuration from database.yml' do
        expect(config.activerecord_configuration).to be_a ActiveRecord::DatabaseConfigurations::HashConfig
      end
    end

    context 'when custom_config is provided' do
      let(:custom_config) do
        {
          adapter: 'postgresql',
          database: 'custom_db',
          host: 'custom.host',
          port: 5433,
          username: 'custom_user',
          password: 'custom_pass'
        }
      end

      subject(:config) { described_class.new('custom_connection', custom_config: custom_config) }

      it 'uses custom configuration instead of database.yml' do
        expect(config.connection_name).to eq('custom_connection')
      end

      it 'returns activerecord configuration with custom values' do
        ar_config = config.activerecord_configuration
        expect(ar_config).to be_a ActiveRecord::DatabaseConfigurations::HashConfig
        expect(ar_config.configuration_hash[:database]).to eq('custom_db')
        expect(ar_config.configuration_hash[:host]).to eq('custom.host')
        expect(ar_config.configuration_hash[:port]).to eq(5433)
        expect(ar_config.configuration_hash[:username]).to eq('custom_user')
      end

      it 'merges default values with custom config' do
        ar_vars = config.activerecord_variables
        expect(ar_vars[:adapter]).to eq('postgresql')
        expect(ar_vars[:database]).to eq('custom_db')
        expect(ar_vars[:host]).to eq('custom.host')
        expect(ar_vars[:port]).to eq(5433)
        expect(ar_vars[:encoding]).to eq('unicode')
        expect(ar_vars[:pool]).to eq(5)
      end

      it 'generates pg_env_variables from custom config' do
        pg_vars = config.pg_env_variables
        expect(pg_vars['PGHOST']).to eq('custom.host')
        expect(pg_vars['PGPORT']).to eq('5433')
        expect(pg_vars['PGUSER']).to eq('custom_user')
        expect(pg_vars['PGPASSWORD']).to eq('custom_pass')
      end

      it 'does not process ENV overrides for custom configs' do
        stub_env('GITLAB_BACKUP_PGHOST', 'override.host')
        stub_env('GITLAB_BACKUP_PGUSER', 'override_user')

        pg_vars = config.pg_env_variables
        expect(pg_vars['PGHOST']).to eq('custom.host')
        expect(pg_vars['PGUSER']).to eq('custom_user')
      end

      context 'when missing required keys' do
        let(:custom_config) { { host: 'localhost' } }

        it 'raises ArgumentError' do
          expect { config }.to raise_error(ArgumentError, /missing required keys/)
        end
      end

      context 'when missing adapter' do
        let(:custom_config) { { database: 'test_db' } }

        it 'raises ArgumentError' do
          expect { config }.to raise_error(ArgumentError, /missing required keys: adapter/)
        end
      end

      context 'when missing database' do
        let(:custom_config) { { adapter: 'postgresql' } }

        it 'raises ArgumentError' do
          expect { config }.to raise_error(ArgumentError, /missing required keys: database/)
        end
      end

      context 'with minimal config' do
        let(:custom_config) do
          {
            adapter: 'postgresql',
            database: 'minimal_db'
          }
        end

        it 'applies defaults for optional keys' do
          ar_vars = config.activerecord_variables
          expect(ar_vars[:host]).to eq('localhost')
          expect(ar_vars[:port]).to eq(5432)
          expect(ar_vars[:pool]).to eq(5)
          expect(ar_vars[:encoding]).to eq('unicode')
        end
      end
    end
  end
end
