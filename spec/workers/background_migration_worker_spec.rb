require 'spec_helper'

describe BackgroundMigrationWorker, :sidekiq, :clean_gitlab_redis_shared_state do
  let(:worker) { described_class.new }

  describe '.perform' do
    it 'performs a background migration' do
      expect(Gitlab::BackgroundMigration)
        .to receive(:perform)
        .with('Foo', [10, 20])

      worker.perform('Foo', [10, 20])
    end

    it 'reschedules a migration if it was performed recently' do
      expect(worker)
        .to receive(:always_perform?)
        .and_return(false)

      worker.lease_for('Foo').try_obtain

      expect(Gitlab::BackgroundMigration)
        .not_to receive(:perform)

      expect(described_class)
        .to receive(:perform_in)
        .with(a_kind_of(Numeric), 'Foo', [10, 20])

      worker.perform('Foo', [10, 20])
    end
  end
end
