# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackgroundMigrationWorker, :clean_gitlab_redis_shared_state do
  let(:worker) { described_class.new }

  describe '.minimum_interval' do
    it 'returns 2 minutes' do
      expect(described_class.minimum_interval).to eq(2.minutes.to_i)
    end
  end

  describe '#perform' do
    before do
      allow(worker).to receive(:jid).and_return(1)
      expect(worker).to receive(:always_perform?).and_return(false)
    end

    context 'when lease can be obtained' do
      before do
        expect(Gitlab::BackgroundMigration)
          .to receive(:perform)
          .with('Foo', [10, 20])
      end

      it 'performs a background migration' do
        worker.perform('Foo', [10, 20])
      end

      context 'when lease_attempts is 1' do
        it 'performs a background migration' do
          worker.perform('Foo', [10, 20], 1)
        end
      end
    end

    context 'when lease not obtained (migration of same class was performed recently)' do
      before do
        expect(Gitlab::BackgroundMigration).not_to receive(:perform)

        worker.lease_for('Foo').try_obtain
      end

      it 'reschedules the migration and decrements the lease_attempts' do
        expect(described_class)
          .to receive(:perform_in)
          .with(a_kind_of(Numeric), 'Foo', [10, 20], 4)

        worker.perform('Foo', [10, 20], 5)
      end

      context 'when lease_attempts is 1' do
        it 'reschedules the migration and decrements the lease_attempts' do
          expect(described_class)
            .to receive(:perform_in)
            .with(a_kind_of(Numeric), 'Foo', [10, 20], 0)

          worker.perform('Foo', [10, 20], 1)
        end
      end

      context 'when lease_attempts is 0' do
        it 'gives up performing the migration' do
          expect(described_class).not_to receive(:perform_in)
          expect(Sidekiq.logger).to receive(:warn).with(
            class: 'Foo',
            message: 'Job could not get an exclusive lease after several tries. Giving up.',
            job_id: 1)

          worker.perform('Foo', [10, 20], 0)
        end
      end
    end

    context 'when database is not healthy' do
      before do
        allow(worker).to receive(:healthy_database?).and_return(false)
      end

      it 'reschedules a migration if the database is not healthy' do
        expect(described_class)
          .to receive(:perform_in)
          .with(a_kind_of(Numeric), 'Foo', [10, 20], 4)

        worker.perform('Foo', [10, 20])
      end

      context 'when lease_attempts is 0' do
        it 'gives up performing the migration' do
          expect(described_class).not_to receive(:perform_in)
          expect(Sidekiq.logger).to receive(:warn).with(
            class: 'Foo',
            message: 'Database was unhealthy after several tries. Giving up.',
            job_id: 1)

          worker.perform('Foo', [10, 20], 0)
        end
      end
    end

    it 'sets the class that will be executed as the caller_id' do
      expect(Gitlab::BackgroundMigration).to receive(:perform) do
        expect(Gitlab::ApplicationContext.current).to include('meta.caller_id' => 'Foo')
      end

      worker.perform('Foo', [10, 20])
    end
  end

  describe '#healthy_database?' do
    context 'when replication lag is too great' do
      it 'returns false' do
        allow(Postgresql::ReplicationSlot)
          .to receive(:lag_too_great?)
          .and_return(true)

        expect(worker.healthy_database?).to eq(false)
      end

      context 'when replication lag is small enough' do
        it 'returns true' do
          allow(Postgresql::ReplicationSlot)
            .to receive(:lag_too_great?)
            .and_return(false)

          expect(worker.healthy_database?).to eq(true)
        end
      end
    end
  end
end
