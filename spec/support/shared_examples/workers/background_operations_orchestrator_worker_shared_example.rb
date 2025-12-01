# frozen_string_literal: true

RSpec.shared_examples 'background operations orchestrator worker' do
  include ExclusiveLeaseHelpers

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  it 'is a limited capacity worker' do
    expect(described_class.new).to be_a(LimitedCapacity::Worker)
  end

  describe 'defining the job attributes' do
    it 'defines the data_consistency as always' do
      expect(described_class.get_data_consistency_per_database.values.uniq).to eq([:sticky])
    end

    it 'defines the feature_category as database' do
      expect(described_class.get_feature_category).to eq(:database)
    end

    it 'defines the idempotency as false' do
      expect(described_class).not_to be_idempotent
    end

    it 'does not retry failed jobs' do
      expect(described_class.sidekiq_options['retry']).to eq(0)
    end

    it 'does not deduplicate jobs' do
      expect(described_class.get_deduplicate_strategy).to eq(:none)
    end

    it 'defines the queue namespace' do
      expect(described_class.queue_namespace).to eq('background_operations')
    end
  end

  describe '.perform_with_capacity' do
    it 'enqueues jobs without modifying provided arguments' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:remove_failed_jobs)
      end

      args = [['Gitlab::Database::BackgroundOperation::Worker', 1, 1, 'main']]

      expect(described_class).to receive(:bulk_perform_async).with(args)

      described_class.perform_with_capacity(args)
    end
  end

  describe '.max_running_jobs' do
    it 'returns the default 10' do
      expect(described_class.max_running_jobs).to eq(10)
    end

    it 'returns updated background_operations_max_jobs from application setting' do
      stub_application_setting(background_operations_max_jobs: 3)

      expect(described_class.max_running_jobs).to eq(3)
    end
  end

  describe '#remaining_work_count' do
    it 'returns 0' do
      expect(described_class.new.remaining_work_count).to eq(0)
    end
  end

  describe '#max_running_jobs' do
    it 'returns the default 10' do
      expect(described_class.new.max_running_jobs).to eq(10)
    end

    it 'returns updated background_operations_max_jobs from application setting' do
      stub_application_setting(background_operations_max_jobs: 5)

      expect(described_class.new.max_running_jobs).to eq(5)
    end
  end

  describe '#perform_work' do
    let(:worker_class) { 'Gitlab::Database::BackgroundOperation::Worker' }
    let(:partition) { 1 }
    let(:database_name) { Gitlab::Database::MAIN_DATABASE_NAME.to_sym }
    let(:base_model) { Gitlab::Database.database_base_models[database_name] }
    let(:table_name) { :events }
    let(:job_interval) { 5.minutes }
    let(:lease_timeout) { job_interval * described_class::LEASE_TIMEOUT_MULTIPLIER }
    let(:interval_variance) { described_class::INTERVAL_VARIANCE }
    let(:worker_id) { worker.attributes['id'] }
    let(:orchestrator) { described_class.new }

    subject(:perform_work) { orchestrator.perform_work(worker_class, partition, worker_id, database_name) }

    context 'when the provided database is sharing config' do
      let(:worker_id) { 123 }
      let(:database_name) { 'ci' }

      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'does nothing' do
        ci_model = Gitlab::Database.database_base_models['ci']
        expect(Gitlab::Database).to receive(:db_config_share_with)
                                      .with(ci_model.connection_db_config).and_return('main')

        expect(orchestrator).not_to receive(:find_worker)
        expect(orchestrator).not_to receive(:run_operation_job)

        perform_work
      end
    end

    context 'when operation does not exist' do
      let(:worker_id) { non_existing_record_id }

      it 'does nothing' do
        expect(orchestrator).not_to receive(:run_operation_job)

        perform_work
      end
    end

    context 'when operation exist' do
      let(:worker) do
        create(:background_operation_worker, :queued, table_name: table_name, interval: job_interval)
      end

      context 'when the operation is no longer active' do
        it 'does not run the operation' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

          worker.hold!

          expect(orchestrator).not_to receive(:run_operation_job)

          perform_work
        end
      end

      context 'when worker is not runnable (elapsed interval)' do
        it 'does not run the operation' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

          expect(orchestrator).to receive(:runnable_worker?).and_return(false)

          expect(orchestrator).not_to receive(:run_operation_job)

          perform_work
        end
      end

      context 'when the operation is still active and the interval has elapsed' do
        let(:lease_key) do
          [
            database_name,
            worker.class.name.underscore,
            worker.table_name,
            worker.id
          ].join(':')
        end

        context 'when can not obtain lease on the table name' do
          it 'does nothing' do
            stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

            expect(orchestrator).not_to receive(:run_operation_job)

            perform_work
          end
        end

        it 'always cleans up the exclusive lease' do
          expect_to_obtain_exclusive_lease(lease_key, 'uuid-table-name', timeout: lease_timeout)
          expect_to_cancel_exclusive_lease(lease_key, 'uuid-table-name')

          expect(orchestrator).to receive(:run_operation_job).and_raise(RuntimeError, 'I broke')

          expect { perform_work }.to raise_error(RuntimeError, 'I broke')
        end

        it 'runs the operation' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(base_model.connection).and_yield

          expect_next_instance_of(Gitlab::Database::BackgroundOperation::Runner) do |instance|
            expect(instance).to receive(:run_operation_job).with(worker)
          end

          expect_to_obtain_exclusive_lease(lease_key, 'uuid-table-name', timeout: lease_timeout)
          expect_to_cancel_exclusive_lease(lease_key, 'uuid-table-name')

          expect(orchestrator).to receive(:run_operation_job).and_call_original

          perform_work
        end
      end
    end
  end
end
