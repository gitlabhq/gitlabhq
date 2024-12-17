# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers, feature_category: :database do
  let(:migration_class) do
    Class.new(ActiveRecord::Migration[6.1])
      .include(described_class)
      .include(Gitlab::Database::Migrations::ReestablishedConnectionStack)
  end

  let(:migration) do
    migration_class.new
  end

  describe '#queue_batched_background_migration' do
    let(:pgclass_info) { instance_double('Gitlab::Database::PgClass', cardinality_estimate: 42) }
    let(:job_class) do
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        def self.name
          'MyJobClass'
        end
      end
    end

    before do
      allow(Gitlab::Database::PgClass).to receive(:for_table).and_call_original
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

      allow(migration).to receive(:transaction_open?).and_return(false)

      stub_const("Gitlab::Database::BackgroundMigration::BatchedMigration::JOB_CLASS_MODULE", '')
      allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigration) do |batched_migration|
        allow(batched_migration).to receive(:job_class)
          .and_return(job_class)
      end
    end

    context 'when such migration already exists' do
      before do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]],
          gitlab_schema: :gitlab_main
        )
      end

      it 'does not create duplicate migration' do
        expect do
          migration.queue_batched_background_migration(
            job_class.name,
            :projects,
            :id,
            [:id], [:id_convert_to_bigint],
            job_interval: 5.minutes,
            batch_min_value: 5,
            batch_max_value: 1000,
            batch_class_name: 'MyBatchClass',
            batch_size: 100,
            sub_batch_size: 10,
            gitlab_schema: :gitlab_main)
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end

      context 'with different but compatible gitlab_schema' do
        it 'does not create duplicate migration' do
          expect do
            migration.queue_batched_background_migration(
              job_class.name,
              :projects,
              :id,
              [:id], [:id_convert_to_bigint],
              job_interval: 5.minutes,
              batch_min_value: 5,
              batch_max_value: 1000,
              batch_class_name: 'MyBatchClass',
              batch_size: 100,
              sub_batch_size: 10,
              gitlab_schema: :gitlab_main_cell)
          end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
        end
      end
    end

    context "when the migration doesn't exist already" do
      let(:version) { '20231204101122' }

      before do
        allow(Gitlab::Database::PgClass).to receive(:for_table).with(:projects).and_return(pgclass_info)
        allow(migration).to receive(:version).and_return(version)
      end

      subject(:enqueue_batched_background_migration) do
        migration.queue_batched_background_migration(
          job_class.name,
          :projects,
          :id,
          job_interval: 5.minutes,
          batch_min_value: 5,
          batch_max_value: 1000,
          batch_class_name: 'MyBatchClass',
          batch_size: 100,
          max_batch_size: 10000,
          sub_batch_size: 10,
          gitlab_schema: :gitlab_ci
        )
      end

      it 'enqueues exactly one batched migration' do
        expect { enqueue_batched_background_migration }
          .to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)
      end

      it 'creates the database record for the migration' do
        batched_background_migration = enqueue_batched_background_migration

        expect(batched_background_migration.reload).to have_attributes(
          job_class_name: 'MyJobClass',
          table_name: 'projects',
          column_name: 'id',
          interval: 300,
          min_value: 5,
          max_value: 1000,
          batch_class_name: 'MyBatchClass',
          batch_size: 100,
          max_batch_size: 10000,
          sub_batch_size: 10,
          job_arguments: %w[],
          status_name: :active,
          total_tuple_count: pgclass_info.cardinality_estimate,
          gitlab_schema: 'gitlab_ci',
          queued_migration_version: version
        )
      end
    end

    context 'when the job interval is lower than the minimum' do
      let(:minimum_delay) { described_class::BATCH_MIN_DELAY }

      it 'sets the job interval to the minimum value' do
        expect do
          migration.queue_batched_background_migration(job_class.name, :events, :id, job_interval: minimum_delay - 1.minute)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.interval).to eq(minimum_delay)
      end
    end

    context 'when additional arguments are passed to the method' do
      context 'when the job class provides job_arguments_count' do
        context 'when defined job arguments for the job class does not match provided arguments' do
          it 'raises an error' do
            expect do
              migration.queue_batched_background_migration(
                job_class.name,
                :projects,
                :id,
                'my',
                'arguments',
                job_interval: 2.minutes)
            end.to raise_error(RuntimeError, /Wrong number of job arguments for MyJobClass \(given 2, expected 0\)/)
          end
        end

        context 'when defined job arguments for the job class match provided arguments' do
          let(:job_class) do
            Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
              def self.name
                'MyJobClass'
              end

              job_arguments :foo, :bar
            end
          end

          it 'saves the arguments on the database record' do
            expect do
              migration.queue_batched_background_migration(
                job_class.name,
                :projects,
                :id,
                'my',
                'arguments',
                job_interval: 5.minutes,
                batch_max_value: 1000)
            end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

            expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to have_attributes(
              job_class_name: 'MyJobClass',
              table_name: 'projects',
              column_name: 'id',
              interval: 300,
              min_value: 1,
              max_value: 1000,
              job_arguments: %w[my arguments])
          end
        end
      end

      context 'when the job class does not provide job_arguments_count' do
        let(:job_class) do
          Class.new do
            def self.name
              'MyJobClass'
            end
          end
        end

        it 'does not raise an error' do
          expect do
            migration.queue_batched_background_migration(
              job_class.name,
              :projects,
              :id,
              'my',
              'arguments',
              job_interval: 2.minutes)
          end.not_to raise_error
        end
      end
    end

    context 'when the max_value is not given' do
      context 'when records exist in the database' do
        let!(:event1) { create(:event) }
        let!(:event2) { create(:event) }
        let!(:event3) { create(:event) }

        it 'creates the record with the current max value' do
          expect do
            migration.queue_batched_background_migration(job_class.name, :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(event3.id)
        end

        it 'creates the record with an active status' do
          expect do
            migration.queue_batched_background_migration(job_class.name, :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_active
        end
      end

      context 'when the database is empty' do
        it 'sets the max value to the min value' do
          expect do
            migration.queue_batched_background_migration(job_class.name, :events, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

          expect(created_migration.max_value).to eq(created_migration.min_value)
        end

        it 'creates the record with a finished status' do
          expect do
            migration.queue_batched_background_migration(job_class.name, :projects, :id, job_interval: 5.minutes)
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.last).to be_finished
        end
      end
    end

    context 'when gitlab_schema is not given' do
      it 'fetches gitlab_schema from the migration context' do
        expect(migration).to receive(:gitlab_schema_from_context).and_return(:gitlab_ci)

        expect do
          migration.queue_batched_background_migration(job_class.name, :events, :id, job_interval: 5.minutes)
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(1)

        created_migration = Gitlab::Database::BackgroundMigration::BatchedMigration.last

        expect(created_migration.gitlab_schema).to eq('gitlab_ci')
      end
    end
  end

  describe '#finalize_batched_background_migration' do
    let!(:batched_migration) { create(:batched_background_migration, job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: []) }

    before do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

      allow(migration).to receive(:transaction_open?).and_return(false)
    end

    context 'when the migration exists' do
      it 'finalizes the migration' do
        allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
          expect(runner).to receive(:finalize).with('MyClass', :projects, :id, [])
        end

        migration.finalize_batched_background_migration(job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: [])
      end

      context 'when different but compatible gitlab_schema' do
        before do
          allow(migration).to receive(:gitlab_schema_from_context).and_return(:gitlab_main_cell)
        end

        it 'finalizes the migration' do
          allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
            expect(runner).to receive(:finalize).with('MyClass', :projects, :id, [])
          end

          migration.finalize_batched_background_migration(job_class_name: 'MyClass', table_name: :projects, column_name: :id, job_arguments: [])
        end
      end
    end

    context 'when the migration does not exist' do
      it 'raises an exception' do
        expect do
          migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: [])
        end.to raise_error(RuntimeError, 'Could not find batched background migration')
      end
    end

    context 'when within transaction' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'does raise an exception' do
        expect { migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: []) }
          .to raise_error(/`finalize_batched_background_migration` cannot be run inside a transaction./)
      end
    end

    context 'when running migration in reconfigured ActiveRecord::Base context' do
      it_behaves_like 'reconfigures connection stack', 'ci' do
        before do
          create(:batched_background_migration,
            job_class_name: 'Ci::MyClass',
            table_name: :ci_builds,
            column_name: :id,
            job_arguments: [],
            gitlab_schema: :gitlab_ci)
        end

        context 'when restrict_gitlab_migration is set to gitlab_ci' do
          it 'finalizes the migration' do
            migration_class.include(Gitlab::Database::MigrationHelpers::RestrictGitlabSchema)
            migration_class.restrict_gitlab_migration gitlab_schema: :gitlab_ci

            allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
              expect(runner).to receive(:finalize).with('Ci::MyClass', :ci_builds, :id, []) do
                validate_connections_stack!
              end
            end

            migration.finalize_batched_background_migration(
              job_class_name: 'Ci::MyClass', table_name: :ci_builds, column_name: :id, job_arguments: [])
          end
        end

        context 'when restrict_gitlab_migration is set to gitlab_main' do
          it 'does not find any migrations' do
            migration_class.include(Gitlab::Database::MigrationHelpers::RestrictGitlabSchema)
            migration_class.restrict_gitlab_migration gitlab_schema: :gitlab_main

            expect do
              migration.finalize_batched_background_migration(
                job_class_name: 'Ci::MyClass', table_name: :ci_builds, column_name: :id, job_arguments: [])
            end.to raise_error(/Could not find batched background migration/)
          end
        end

        context 'when no restrict is set' do
          it 'does not find any migrations' do
            expect do
              migration.finalize_batched_background_migration(
                job_class_name: 'Ci::MyClass', table_name: :ci_builds, column_name: :id, job_arguments: [])
            end.to raise_error(/Could not find batched background migration/)
          end
        end
      end
    end

    context 'when within transaction' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'does raise an exception' do
        expect { migration.finalize_batched_background_migration(job_class_name: 'MyJobClass', table_name: :projects, column_name: :id, job_arguments: []) }
          .to raise_error(/`finalize_batched_background_migration` cannot be run inside a transaction./)
      end
    end
  end

  describe '#delete_batched_background_migration' do
    before do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)
    end

    context 'when migration exists' do
      before do
        create(
          :batched_background_migration,
          job_class_name: 'MyJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )
      end

      it 'deletes it' do
        expect do
          migration.delete_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [[:id], [:id_convert_to_bigint]])
        end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.from(1).to(0)
      end

      context 'with different but compatible gitlab_schema' do
        before do
          allow(migration).to receive(:gitlab_schema_from_context).and_return(:gitlab_main_cell)
        end

        it 'deletes it' do
          expect do
            migration.delete_batched_background_migration(
              'MyJobClass',
              :projects,
              :id,
              [[:id], [:id_convert_to_bigint]])
          end.to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }.from(1).to(0)
        end
      end
    end

    context 'when migration does not exist' do
      it 'does nothing' do
        create(
          :batched_background_migration,
          job_class_name: 'SomeOtherJobClass',
          table_name: :projects,
          column_name: :id,
          interval: 10.minutes,
          min_value: 5,
          max_value: 1005,
          batch_class_name: 'MyBatchClass',
          batch_size: 200,
          sub_batch_size: 20,
          job_arguments: [[:id], [:id_convert_to_bigint]]
        )

        expect do
          migration.delete_batched_background_migration(
            'MyJobClass',
            :projects,
            :id,
            [[:id], [:id_convert_to_bigint]])
        end.not_to change { Gitlab::Database::BackgroundMigration::BatchedMigration.count }
      end
    end
  end

  describe '#gitlab_schema_from_context' do
    context 'when allowed_gitlab_schemas is not available' do
      it 'defaults to :gitlab_main' do
        expect(migration.gitlab_schema_from_context).to eq(:gitlab_main)
      end
    end

    context 'when allowed_gitlab_schemas is available' do
      it 'uses schema from allowed_gitlab_schema' do
        expect(migration).to receive(:allowed_gitlab_schemas).and_return([:gitlab_ci])

        expect(migration.gitlab_schema_from_context).to eq(:gitlab_ci)
      end
    end
  end

  shared_examples 'invalid early finalization' do
    it 'throws an early finalization error' do
      expect { ensure_batched_background_migration_is_finished }.to raise_error(described_class::EARLY_FINALIZATION_ERROR)
    end
  end

  shared_examples 'valid finalization' do
    it 'does not throw any error' do
      expect { ensure_batched_background_migration_is_finished }.not_to raise_error
    end
  end

  describe '#ensure_batched_background_migration_is_finished' do
    let(:job_class_name) { 'CopyColumnUsingBackgroundMigrationJob' }
    let(:table_name) { '_test_table' }
    let(:column_name) { :id }
    let(:job_arguments) { [["id"], ["id_convert_to_bigint"], nil] }
    let(:gitlab_schema) { :gitlab_main }

    let(:configuration) do
      {
        job_class_name: job_class_name,
        table_name: table_name,
        column_name: column_name,
        job_arguments: job_arguments
      }
    end

    let(:migration_attributes) do
      configuration.merge(
        gitlab_schema: gitlab_schema,
        queued_migration_version: Time.now.utc.strftime("%Y%m%d%H%M%S")
      )
    end

    before do
      allow(migration).to receive(:transaction_open?).and_return(false)
      allow(migration).to receive(:version).and_return('20240905124118')
    end

    subject(:ensure_batched_background_migration_is_finished) { migration.ensure_batched_background_migration_is_finished(**configuration) }

    it 'raises an error when migration exists and is not marked as finished' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!).twice

      create(:batched_background_migration, :active, migration_attributes)

      allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
        allow(runner).to receive(:finalize).with(job_class_name, table_name, column_name, job_arguments).and_return(false)
      end

      expect { ensure_batched_background_migration_is_finished }
        .to raise_error "Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':" \
            "\t#{configuration}" \
            "\n\n" \
            "Finalize it manually by running the following command in a `bash` or `sh` shell:" \
            "\n\n" \
            "\tsudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,_test_table,id,'[[\"id\"]\\,[\"id_convert_to_bigint\"]\\,null]']" \
            "\n\n" \
            "For more information, check the documentation" \
            "\n\n" \
            "\thttps://docs.gitlab.com/ee/update/background_migrations.html#database-migrations-failing-because-of-batched-background-migration-not-finished"
    end

    it 'does not raise error when migration exists and is marked as finished' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

      create(:batched_background_migration, :finished, migration_attributes)

      expect { ensure_batched_background_migration_is_finished }
        .not_to raise_error
    end

    context 'when different but compatible gitlab_schema' do
      before do
        allow(migration).to receive(:gitlab_schema_from_context).and_return(:gitlab_main_cell)
      end

      it 'does not raise error when migration exists and is marked as finished' do
        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

        create(:batched_background_migration, :finished, migration_attributes)

        expect { ensure_batched_background_migration_is_finished }
          .not_to raise_error
      end

      it 'raises an error when migration exists and is not marked as finished' do
        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!).twice

        create(:batched_background_migration, :active, migration_attributes)

        allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
          allow(runner).to receive(:finalize).with(job_class_name, table_name, column_name, job_arguments).and_return(false)
        end

        expect { ensure_batched_background_migration_is_finished }
          .to raise_error "Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':" \
        "\t#{configuration}" \
        "\n\n" \
        "Finalize it manually by running the following command in a `bash` or `sh` shell:" \
        "\n\n" \
        "\tsudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,_test_table,id,'[[\"id\"]\\,[\"id_convert_to_bigint\"]\\,null]']" \
        "\n\n" \
        "For more information, check the documentation" \
        "\n\n" \
        "\thttps://docs.gitlab.com/ee/update/background_migrations.html#database-migrations-failing-because-of-batched-background-migration-not-finished"
      end
    end

    context 'when specified migration does not exist' do
      let(:lab_key) { 'DBLAB_ENVIRONMENT' }

      context 'when DBLAB_ENVIRONMENT is not set' do
        it 'logs a warning' do
          stub_env(lab_key, nil)
          expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

          create(:batched_background_migration, :active, migration_attributes.merge(gitlab_schema: :gitlab_something_else))

          expect(Gitlab::AppLogger).to receive(:warn)
            .with("Could not find batched background migration for the given configuration: #{configuration}")

          expect { ensure_batched_background_migration_is_finished }
            .not_to raise_error
        end
      end

      context 'when DBLAB_ENVIRONMENT is set' do
        it 'raises an error' do
          stub_env(lab_key, 'foo')
          expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

          create(:batched_background_migration, :active, migration_attributes.merge(gitlab_schema: :gitlab_something_else))

          expect { ensure_batched_background_migration_is_finished }
            .to raise_error(Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::NonExistentMigrationError)
        end
      end
    end

    context 'when the migration is `finished`' do
      let(:finished_status) { 3 }
      let(:finalized_status) { 6 }
      let(:migration_record) { create(:batched_background_migration, :finished) }

      let(:configuration) do
        {
          job_class_name: migration_record.job_class_name,
          table_name: migration_record.table_name,
          column_name: migration_record.column_name,
          job_arguments: migration_record.job_arguments
        }
      end

      it 'updates the status to `finalized`' do
        expect { ensure_batched_background_migration_is_finished }.to change { migration_record.reload.status }.from(finished_status).to(finalized_status)
      end
    end

    context 'when within transaction' do
      before do
        allow(migration).to receive(:transaction_open?).and_return(true)
      end

      it 'does raise an exception' do
        expect { ensure_batched_background_migration_is_finished }
          .to raise_error(/`ensure_batched_background_migration_is_finished` cannot be run inside a transaction./)
      end
    end

    it 'finalizes the migration' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!).twice

      migration = create(:batched_background_migration, :active, configuration)

      allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
        expect(runner).to receive(:finalize).with(job_class_name, table_name, column_name, job_arguments).and_return(migration.finish!)
      end

      ensure_batched_background_migration_is_finished
    end

    context 'when the flag finalize is false' do
      it 'does not finalize the migration' do
        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

        create(:batched_background_migration, :active, configuration)

        allow_next_instance_of(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner) do |runner|
          expect(runner).not_to receive(:finalize).with(job_class_name, table_name, column_name, job_arguments)
        end

        expect { migration.ensure_batched_background_migration_is_finished(**configuration.merge(finalize: false)) }.to raise_error(RuntimeError)
      end
    end

    context 'with finalized migration' do
      let(:migration_attributes) do
        configuration
          .except(:skip_early_finalization_validation)
          .merge(queued_migration_version: '20240905124118')
      end

      before do
        allow(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_dml_mode!)

        create(:batched_background_migration, :finalized, migration_attributes)
      end

      context 'when the migration does not have queued_migration_version attr' do
        let(:migration_attributes) { configuration.merge(queued_migration_version: nil) }

        it_behaves_like 'valid finalization'
      end

      context 'when the migration version is before ENFORCE_EARLY_FINALIZATION_FROM_VERSION' do
        let(:migration_attributes) { configuration.merge(queued_migration_version: '20240905124116') }

        it_behaves_like 'valid finalization'
      end

      context 'when the migration is queued after the last required stop' do
        before do
          stub_bbm_stops('16.11', '17.2')
        end

        it_behaves_like 'invalid early finalization'

        context 'with skip_early_finalization_validation enabled' do
          let(:configuration) do
            {
              job_class_name: job_class_name,
              table_name: table_name,
              column_name: column_name,
              job_arguments: job_arguments,
              skip_early_finalization_validation: true
            }
          end

          it_behaves_like 'valid finalization'
        end
      end

      context 'when the migration is queued on the last required stop' do
        before do
          stub_bbm_stops('16.11', '16.11')
        end

        it_behaves_like 'valid finalization'
      end

      context 'when the migration is queued before the last required stop' do
        before do
          stub_bbm_stops('16.11', '16.10')
        end

        it_behaves_like 'valid finalization'
      end
    end
  end

  def stub_bbm_stops(last_required_stop, queued_milestone)
    allow_next_instance_of(Gitlab::Utils::BatchedBackgroundMigrationsDictionary) do |dict|
      allow(dict).to receive(:milestone).and_return(queued_milestone)
    end

    allow_next_instance_of(Gitlab::Utils::UpgradePath) do |ugrade_path|
      allow(ugrade_path).to receive(:last_required_stop).and_return(Gitlab::VersionInfo.parse_from_milestone(last_required_stop))
    end
  end
end
