# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::DatabaseModel, :reestablished_active_record_base, feature_category: :backup_restore do
  using RSpec::Parameterized::TableSyntax

  let(:gitlab_database_name) { 'main' }

  describe '#connection' do
    subject(:connection) { described_class.new(gitlab_database_name).connection }

    it 'an instance of a ActiveRecord::Base.connection' do
      connection.is_a? ActiveRecord::Base.connection.class # rubocop:disable Database/MultipleDatabases -- We actually need an ActiveRecord::Base here
    end
  end

  describe '#config' do
    let(:application_config) do
      {
        adapter: 'postgresql',
        host: 'some_host',
        port: '5432'
      }
    end

    subject(:config) { described_class.new(gitlab_database_name).config }

    before do
      allow(
        Gitlab::Database.database_base_models_with_gitlab_shared[gitlab_database_name].connection_db_config
      ).to receive(:configuration_hash).and_return(application_config)
    end

    shared_examples 'no configuration is overridden' do
      it 'ActiveRecord backup configuration is expected to equal application configuration' do
        expect(config[:activerecord]).to eq(application_config)
      end

      it 'PostgreSQL ENV is expected to equal application configuration' do
        expect(config[:pg_env]).to eq(
          {
            'PGHOST' => application_config[:host],
            'PGPORT' => application_config[:port]
          }
        )
      end
    end

    shared_examples 'environment variables override application configuration' do
      let(:active_record_key) { described_class::SUPPORTED_OVERRIDES.invert[pg_env] }

      it 'ActiveRecord backup configuration overrides application configuration' do
        expect(config[:activerecord]).to eq(application_config.merge(active_record_key => overridden_value))
      end

      it 'PostgreSQL ENV overrides application configuration' do
        expect(config[:pg_env]).to include({ pg_env => overridden_value })
      end
    end

    context 'when no GITLAB_BACKUP_PG* variables are set' do
      it_behaves_like 'no configuration is overridden'
    end

    context 'when generic database configuration is overridden' do
      where(:env_variable, :overridden_value) do
        'GITLAB_BACKUP_PGHOST'           | 'test.invalid.'
        'GITLAB_BACKUP_PGUSER'           | 'some_user'
        'GITLAB_BACKUP_PGPORT'           | '1543'
        'GITLAB_BACKUP_PGPASSWORD'       | 'secret'
        'GITLAB_BACKUP_PGSSLMODE'        | 'allow'
        'GITLAB_BACKUP_PGSSLKEY'         | 'some_key'
        'GITLAB_BACKUP_PGSSLCERT'        | '/path/to/cert'
        'GITLAB_BACKUP_PGSSLROOTCERT'    | '/path/to/root/cert'
        'GITLAB_BACKUP_PGSSLCRL'         | '/path/to/crl'
        'GITLAB_BACKUP_PGSSLCOMPRESSION' | '1'
        'GITLAB_OVERRIDE_PGHOST'           | 'test.invalid.'
        'GITLAB_OVERRIDE_PGUSER'           | 'some_user'
        'GITLAB_OVERRIDE_PGPORT'           | '1543'
        'GITLAB_OVERRIDE_PGPASSWORD'       | 'secret'
        'GITLAB_OVERRIDE_PGSSLMODE'        | 'allow'
        'GITLAB_OVERRIDE_PGSSLKEY'         | 'some_key'
        'GITLAB_OVERRIDE_PGSSLCERT'        | '/path/to/cert'
        'GITLAB_OVERRIDE_PGSSLROOTCERT'    | '/path/to/root/cert'
        'GITLAB_OVERRIDE_PGSSLCRL'         | '/path/to/crl'
        'GITLAB_OVERRIDE_PGSSLCOMPRESSION' | '1'
      end

      with_them do
        let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_(\w+)/, 2] }

        before do
          stub_env(env_variable, overridden_value)
        end

        it_behaves_like 'environment variables override application configuration'
      end
    end

    context 'when specific database configuration is overridden' do
      context 'and environment variables are for the current database name' do
        where(:env_variable, :overridden_value) do
          'GITLAB_BACKUP_MAIN_PGHOST'           | 'test.invalid.'
          'GITLAB_BACKUP_MAIN_PGUSER'           | 'some_user'
          'GITLAB_BACKUP_MAIN_PGPORT'           | '1543'
          'GITLAB_BACKUP_MAIN_PGPASSWORD'       | 'secret'
          'GITLAB_BACKUP_MAIN_PGSSLMODE'        | 'allow'
          'GITLAB_BACKUP_MAIN_PGSSLKEY'         | 'some_key'
          'GITLAB_BACKUP_MAIN_PGSSLCERT'        | '/path/to/cert'
          'GITLAB_BACKUP_MAIN_PGSSLROOTCERT'    | '/path/to/root/cert'
          'GITLAB_BACKUP_MAIN_PGSSLCRL'         | '/path/to/crl'
          'GITLAB_BACKUP_MAIN_PGSSLCOMPRESSION' | '1'
          'GITLAB_OVERRIDE_MAIN_PGHOST'           | 'test.invalid.'
          'GITLAB_OVERRIDE_MAIN_PGUSER'           | 'some_user'
          'GITLAB_OVERRIDE_MAIN_PGPORT'           | '1543'
          'GITLAB_OVERRIDE_MAIN_PGPASSWORD'       | 'secret'
          'GITLAB_OVERRIDE_MAIN_PGSSLMODE'        | 'allow'
          'GITLAB_OVERRIDE_MAIN_PGSSLKEY'         | 'some_key'
          'GITLAB_OVERRIDE_MAIN_PGSSLCERT'        | '/path/to/cert'
          'GITLAB_OVERRIDE_MAIN_PGSSLROOTCERT'    | '/path/to/root/cert'
          'GITLAB_OVERRIDE_MAIN_PGSSLCRL'         | '/path/to/crl'
          'GITLAB_OVERRIDE_MAIN_PGSSLCOMPRESSION' | '1'
        end

        with_them do
          let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_MAIN_(\w+)/, 2] }

          before do
            stub_env(env_variable, overridden_value)
          end

          it_behaves_like 'environment variables override application configuration'
        end
      end

      context 'and environment variables are for another database' do
        where(:env_variable, :overridden_value) do
          'GITLAB_BACKUP_CI_PGHOST'           | 'test.invalid.'
          'GITLAB_BACKUP_CI_PGUSER'           | 'some_user'
          'GITLAB_BACKUP_CI_PGPORT'           | '1543'
          'GITLAB_BACKUP_CI_PGPASSWORD'       | 'secret'
          'GITLAB_BACKUP_CI_PGSSLMODE'        | 'allow'
          'GITLAB_BACKUP_CI_PGSSLKEY'         | 'some_key'
          'GITLAB_BACKUP_CI_PGSSLCERT'        | '/path/to/cert'
          'GITLAB_BACKUP_CI_PGSSLROOTCERT'    | '/path/to/root/cert'
          'GITLAB_BACKUP_CI_PGSSLCRL'         | '/path/to/crl'
          'GITLAB_BACKUP_CI_PGSSLCOMPRESSION' | '1'
          'GITLAB_OVERRIDE_CI_PGHOST'           | 'test.invalid.'
          'GITLAB_OVERRIDE_CI_PGUSER'           | 'some_user'
          'GITLAB_OVERRIDE_CI_PGPORT'           | '1543'
          'GITLAB_OVERRIDE_CI_PGPASSWORD'       | 'secret'
          'GITLAB_OVERRIDE_CI_PGSSLMODE'        | 'allow'
          'GITLAB_OVERRIDE_CI_PGSSLKEY'         | 'some_key'
          'GITLAB_OVERRIDE_CI_PGSSLCERT'        | '/path/to/cert'
          'GITLAB_OVERRIDE_CI_PGSSLROOTCERT'    | '/path/to/root/cert'
          'GITLAB_OVERRIDE_CI_PGSSLCRL'         | '/path/to/crl'
          'GITLAB_OVERRIDE_CI_PGSSLCOMPRESSION' | '1'
        end

        with_them do
          let(:pg_env) { env_variable[/GITLAB_(BACKUP|OVERRIDE)_CI_(\w+)/, 1] }

          before do
            stub_env(env_variable, overridden_value)
          end

          it_behaves_like 'no configuration is overridden'
        end
      end

      context 'when both GITLAB_BACKUP_PGUSER and GITLAB_BACKUP_MAIN_PGUSER variable are present' do
        before do
          stub_env('GITLAB_BACKUP_PGUSER', 'generic_user')
          stub_env('GITLAB_BACKUP_MAIN_PGUSER', 'specfic_user')
        end

        it 'prefers more specific GITLAB_BACKUP_MAIN_PGUSER' do
          expect(config.dig(:activerecord, :username)).to eq('specfic_user')
          expect(config.dig(:pg_env, 'PGUSER')).to eq('specfic_user')
        end
      end
    end
  end
end
