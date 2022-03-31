# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'dev rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/setup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/dev'
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/db'
  end

  describe 'setup' do
    subject(:setup_task) { run_rake_task('dev:setup') }

    let(:connections) { Gitlab::Database.database_base_models.values.map(&:connection) }

    it 'sets up the development environment', :aggregate_failures do
      expect(Rake::Task['gitlab:setup']).to receive(:invoke)

      expect(connections).to all(receive(:execute).with('SET statement_timeout TO 0'))
      expect(connections).to all(receive(:execute).with('ANALYZE'))
      expect(connections).to all(receive(:execute).with('RESET statement_timeout'))

      expect(Rake::Task['gitlab:shell:setup']).to receive(:invoke)

      setup_task
    end
  end

  describe 'load' do
    subject(:load_task) { run_rake_task('dev:load') }

    it 'eager loads the application', :aggregate_failures do
      expect(Rails.configuration).to receive(:eager_load=).with(true)
      expect(Rails.application).to receive(:eager_load!)

      load_task
    end
  end

  context 'multiple databases' do
    before do
      skip_if_multiple_databases_not_setup
    end

    context 'with a valid database' do
      describe 'copy_db:ci' do
        before do
          configurations = instance_double(ActiveRecord::DatabaseConfigurations)
          allow(ActiveRecord::Base).to receive(:configurations).and_return(configurations)
          allow(configurations).to receive(:configs_for).with(env_name: Rails.env, name: 'ci').and_return(ci_configuration)
        end

        subject(:load_task) { run_rake_task('dev:setup_ci_db') }

        let(:ci_configuration) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'ci', database: '__test_db_ci') }

        it 'creates the database from main' do
          expect(ApplicationRecord.connection).to receive(:create_database).with(
            ci_configuration.database,
            template: ApplicationRecord.connection_db_config.database
          )

          run_rake_task('dev:copy_db:ci')
        end

        context 'when the database already exists' do
          it 'prints out a warning' do
            expect(ApplicationRecord.connection).to receive(:create_database).and_raise(ActiveRecord::DatabaseAlreadyExists)

            expect { run_rake_task('dev:copy_db:ci') }.to output(/Database '#{ci_configuration.database}' already exists/).to_stderr
          end
        end
      end
    end

    context 'with an invalid database' do
      it 'raises an error' do
        expect { run_rake_task('dev:copy_db:foo') }.to raise_error(RuntimeError, /Don't know how to build task/)
      end
    end
  end
end
