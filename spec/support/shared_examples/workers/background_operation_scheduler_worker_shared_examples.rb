# frozen_string_literal: true

RSpec.shared_examples 'it schedules background operation workers' do |worker_factory|
  let(:worker) { described_class.new }
  let(:worker_class) { described_class.worker_class }
  let(:tracking_database) { described_class.tracking_database }

  before do
    unless Gitlab::Database.has_config?(tracking_database)
      skip "because the base model for #{tracking_database} does not exist"
    end

    skip_if_shared_database(tracking_database)

    stub_feature_flags(disallow_database_ddl_feature_flags: false)

    create(worker_factory, :active, table_name: 'users')
    create(worker_factory, :paused, table_name: 'issues')
    create(worker_factory, :queued, table_name: 'projects')
    create(worker_factory, :paused, table_name: 'namespaces', on_hold_until: 2.days.ago)
  end

  subject(:schedule_workers) { worker.perform }

  describe 'defining the job attributes' do
    it 'defines idempotent!' do
      expect(described_class.idempotent?).to be_truthy
    end

    it 'defines the feature_category as database' do
      expect(described_class.get_feature_category).to eq(:database)
    end
  end

  describe '#perform' do
    context 'without base_model' do
      before do
        allow(worker).to receive(:base_model).and_return(nil)
      end

      it 'skips scheduling and logs skipping message' do
        expect(worker).not_to receive(:queue_workers_for_execution)

        expect(Sidekiq.logger).to receive(:info) do |payload|
          expect(payload[:class]).to eq(described_class.name)
          expect(payload[:message]).to include('Skipping')
        end

        schedule_workers
      end
    end

    context 'with disallow_database_ddl_feature_flags enabled' do
      before do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)
      end

      it 'skips scheduling' do
        expect(worker).not_to receive(:queue_workers_for_execution)

        schedule_workers
      end
    end

    context 'with feature flags enabled' do
      it 'schedules executable workers for execution' do
        expect(worker).to receive(:queue_workers_for_execution).with(worker_class.schedulable_workers(2))

        schedule_workers
      end
    end
  end
end
