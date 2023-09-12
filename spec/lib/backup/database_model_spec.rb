# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::DatabaseModel, :reestablished_active_record_base, feature_category: :backup_restore do
  let(:gitlab_database_name) { 'main' }

  describe '#connection' do
    subject { described_class.new(gitlab_database_name).connection }

    it 'an instance of a ActiveRecord::Base.connection' do
      subject.is_a? ActiveRecord::Base.connection.class # rubocop:disable Database/MultipleDatabases
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

    subject { described_class.new(gitlab_database_name).config }

    before do
      allow(
        Gitlab::Database.database_base_models_with_gitlab_shared[gitlab_database_name].connection_db_config
      ).to receive(:configuration_hash).and_return(application_config)
    end

    context 'when no GITLAB_BACKUP_PG* variables are set' do
      it 'ActiveRecord backup configuration is expected to equal application configuration' do
        expect(subject[:activerecord]).to eq(application_config)
      end

      it 'PostgreSQL ENV is expected to equal application configuration' do
        expect(subject[:pg_env]).to eq(
          {
            'PGHOST' => application_config[:host],
            'PGPORT' => application_config[:port]
          }
        )
      end
    end

    context 'when GITLAB_BACKUP_PG* variables are set' do
      using RSpec::Parameterized::TableSyntax

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
      end

      with_them do
        let(:pg_env) { env_variable[/GITLAB_BACKUP_(\w+)/, 1] }
        let(:active_record_key) { described_class::SUPPORTED_OVERRIDES.invert[pg_env] }

        before do
          stub_env(env_variable, overridden_value)
        end

        it 'ActiveRecord backup configuration overrides application configuration' do
          expect(subject[:activerecord]).to eq(application_config.merge(active_record_key => overridden_value))
        end

        it 'PostgreSQL ENV overrides application configuration' do
          expect(subject[:pg_env]).to include({ pg_env => overridden_value })
        end
      end
    end
  end
end
