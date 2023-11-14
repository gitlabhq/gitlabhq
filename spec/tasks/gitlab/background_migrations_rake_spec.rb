# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:background_migrations namespace rake tasks', :suppress_gitlab_schemas_validate_connection,
  feature_category: :database do
  before do
    Rake.application.rake_require 'tasks/gitlab/background_migrations'
  end

  describe 'finalize' do
    subject(:finalize_task) { run_rake_task('gitlab:background_migrations:finalize', *arguments) }

    let(:connection) { double(:connection) }
    let(:main_model) { double(:model, connection: connection) }
    let(:base_models) { { main: main_model } }
    let(:databases) { [Gitlab::Database::MAIN_DATABASE_NAME] }

    before do
      allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
      allow(Gitlab::Database).to receive(:db_config_names).with(with_schema: :gitlab_shared).and_return(databases)
    end

    context 'without the proper arguments' do
      let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id] }

      it 'exits without finalizing the migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).not_to receive(:finalize)

        expect { finalize_task }.to output(/Must specify job_arguments as an argument/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context 'with the proper arguments' do
      let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id [["id1"\,"id2"]]] }

      it 'finalizes the matching migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:finalize)
          .with('CopyColumnUsingBackgroundMigrationJob', 'events', 'id', [%w[id1 id2]], connection: connection)

        expect { finalize_task }.to output(/Done/).to_stdout
      end
    end

    context 'with a null parameter' do
      let(:arguments) { %w[ProjectNamespaces::BackfillProjectNamespaces projects id] + ['[null\, "up"]'] }

      it 'finalizes the matching migration' do
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:finalize)
          .with('ProjectNamespaces::BackfillProjectNamespaces', 'projects', 'id', [nil, "up"], connection: connection)

        expect { finalize_task }.to output(/Done/).to_stdout
      end
    end

    context 'when multiple database feature is enabled' do
      subject(:finalize_task) { run_rake_task("gitlab:background_migrations:finalize:#{ci_database_name}", *arguments) }

      let(:ci_database_name) { Gitlab::Database::CI_DATABASE_NAME }
      let(:ci_model) { double(:model, connection: connection) }
      let(:base_models) { { 'main' => main_model, 'ci' => ci_model } }
      let(:databases) { [Gitlab::Database::MAIN_DATABASE_NAME, ci_database_name] }

      before do
        skip_if_shared_database(:ci)

        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
      end

      it 'ignores geo' do
        expect { run_rake_task('gitlab:background_migrations:finalize:geo}') }
          .to raise_error(RuntimeError).with_message(/Don't know how to build task/)
      end

      context 'without the proper arguments' do
        let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id] }

        it 'exits without finalizing the migration' do
          expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).not_to receive(:finalize)

          expect { finalize_task }.to output(/Must specify job_arguments as an argument/).to_stdout
            .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        end
      end

      context 'with the proper arguments' do
        let(:arguments) { %w[CopyColumnUsingBackgroundMigrationJob events id [["id1"\,"id2"]]] }

        it 'finalizes the matching migration' do
          expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:finalize)
            .with('CopyColumnUsingBackgroundMigrationJob', 'events', 'id', [%w[id1 id2]], connection: connection)

          expect { finalize_task }.to output(/Done/).to_stdout
        end
      end

      context 'when database name is not passed' do
        it 'aborts the rake task' do
          expect { run_rake_task('gitlab:background_migrations:finalize') }.to output(/Please specify the database/).to_stdout
            .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        end
      end
    end
  end

  describe 'status' do
    subject(:status_task) { run_rake_task('gitlab:background_migrations:status') }

    let(:migration1) { create(:batched_background_migration, :finished, job_arguments: [%w[id1 id2]]) }
    let(:migration2) { create(:batched_background_migration, :failed, job_arguments: []) }

    let(:main_database_name) { Gitlab::Database::MAIN_DATABASE_NAME }
    let(:model) { Gitlab::Database.database_base_models[main_database_name] }
    let(:connection) { double(:connection) }
    let(:base_models) { { 'main' => model }.with_indifferent_access }

    it 'outputs the status of background migrations' do
      allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)

      expect { status_task }.to output(<<~OUTPUT).to_stdout
        Database: #{main_database_name}
        finished   | #{migration1.job_class_name},#{migration1.table_name},#{migration1.column_name},[["id1","id2"]]
        failed     | #{migration2.job_class_name},#{migration2.table_name},#{migration2.column_name},[]
      OUTPUT
    end

    context 'when running the rake task against one database in multiple databases setup' do
      before do
        skip_if_shared_database(:ci)
      end

      subject(:status_task) { run_rake_task("gitlab:background_migrations:status:#{main_database_name}") }

      it 'outputs the status of background migrations' do
        expect { status_task }.to output(<<~OUTPUT).to_stdout
            Database: #{main_database_name}
            finished   | #{migration1.job_class_name},#{migration1.table_name},#{migration1.column_name},[["id1","id2"]]
            failed     | #{migration2.job_class_name},#{migration2.table_name},#{migration2.column_name},[]
        OUTPUT
      end
    end

    context 'when multiple databases are configured' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      context 'with two connections sharing the same database' do
        before do
          skip_if_database_exists(:ci)
          skip_if_database_exists(:jh)
        end

        it 'skips the shared database' do
          expect { status_task }.to output(<<~OUTPUT).to_stdout
            Database: #{main_database_name}
            finished   | #{migration1.job_class_name},#{migration1.table_name},#{migration1.column_name},[["id1","id2"]]
            failed     | #{migration2.job_class_name},#{migration2.table_name},#{migration2.column_name},[]
          OUTPUT
        end

        it 'ignores geo' do
          expect { run_rake_task('gitlab:background_migrations:status:geo') }
            .to raise_error(RuntimeError).with_message(/Don't know how to build task/)
        end
      end

      context 'with multiple databases' do
        before do
          skip_if_shared_database(:ci)
        end

        subject(:status_task) { run_rake_task('gitlab:background_migrations:status') }

        let(:base_models) { { main: main_model, ci: ci_model } }
        let(:main_model) { double(:model, connection: connection) }
        let(:ci_model) { double(:model, connection: connection) }

        it 'outputs the status for each database' do
          allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
          allow(Gitlab::Database).to receive(:has_database?).with(:main).and_return(true)
          allow(Gitlab::Database).to receive(:has_database?).with(:ci).and_return(true)

          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(main_model.connection).and_yield
          expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_each).and_yield(migration1)

          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield
          expect(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive(:find_each).and_yield(migration2)

          expect { status_task }.to output(<<~OUTPUT).to_stdout
            Database: main
            finished   | #{migration1.job_class_name},#{migration1.table_name},#{migration1.column_name},[["id1","id2"]]
            Database: ci
            failed     | #{migration2.job_class_name},#{migration2.table_name},#{migration2.column_name},[]
          OUTPUT
        end
      end
    end
  end
end
