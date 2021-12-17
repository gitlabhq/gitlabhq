# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration do
  let(:default_tracking_database) { described_class::DEFAULT_TRACKING_DATABASE }
  let(:coordinator) { described_class::JobCoordinator.for_tracking_database(default_tracking_database) }

  before do
    allow(described_class).to receive(:coordinator_for_database)
      .with(default_tracking_database)
      .and_return(coordinator)
  end

  describe '.queue' do
    it 'returns background migration worker queue' do
      expect(described_class.queue)
        .to eq BackgroundMigrationWorker.sidekiq_options['queue']
    end
  end

  describe '.steal' do
    context 'when the queue contains unprocessed jobs' do
      let(:queue) do
        [
          double(args: ['Foo', [10, 20]], klass: 'BackgroundMigrationWorker'),
          double(args: ['Bar', [20, 30]], klass: 'BackgroundMigrationWorker'),
          double(args: ['Foo', [20, 30]], klass: 'MergeWorker')
        ]
      end

      before do
        allow(Sidekiq::Queue).to receive(:new)
          .with(coordinator.queue)
          .and_return(queue)
      end

      it 'uses the coordinator to steal jobs' do
        expect(queue[0]).to receive(:delete).and_return(true)

        expect(coordinator).to receive(:steal).with('Foo', retry_dead_jobs: false).and_call_original
        expect(coordinator).to receive(:perform).with('Foo', [10, 20])

        described_class.steal('Foo')
      end

      context 'when a custom predicate is given' do
        it 'steals jobs that match the predicate' do
          expect(queue[0]).to receive(:delete).and_return(true)

          expect(coordinator).to receive(:perform).with('Foo', [10, 20])

          described_class.steal('Foo') { |job| job.args.second.first == 10 && job.args.second.second == 20 }
        end

        it 'does not steal jobs that do not match the predicate' do
          expect(coordinator).not_to receive(:perform)

          expect(queue[0]).not_to receive(:delete)

          described_class.steal('Foo') { |(arg1, _)| arg1 == 5 }
        end
      end
    end

    context 'when retry_dead_jobs is true', :redis do
      let(:retry_queue) do
        [double(args: ['Object', [3]], klass: 'BackgroundMigrationWorker', delete: true)]
      end

      let(:dead_queue) do
        [double(args: ['Object', [4]], klass: 'BackgroundMigrationWorker', delete: true)]
      end

      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_queue)
        allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_queue)
      end

      it 'steals from the dead and retry queue' do
        Sidekiq::Testing.disable! do
          expect(coordinator).to receive(:perform).with('Object', [1]).ordered
          expect(coordinator).to receive(:perform).with('Object', [2]).ordered
          expect(coordinator).to receive(:perform).with('Object', [3]).ordered
          expect(coordinator).to receive(:perform).with('Object', [4]).ordered

          BackgroundMigrationWorker.perform_async('Object', [2])
          BackgroundMigrationWorker.perform_in(10.minutes, 'Object', [1])

          described_class.steal('Object', retry_dead_jobs: true)
        end
      end
    end
  end

  describe '.perform' do
    let(:migration) { spy(:migration) }

    before do
      stub_const("#{described_class.name}::Foo", migration)
    end

    it 'uses the coordinator to perform a background migration' do
      expect(coordinator).to receive(:perform).with('Foo', [10, 20]).and_call_original
      expect(migration).to receive(:perform).with(10, 20).once

      described_class.perform('Foo', [10, 20])
    end
  end

  describe '.exists?', :redis do
    before do
      Sidekiq::Testing.disable! do
        MergeWorker.perform_async('Bar')
        BackgroundMigrationWorker.perform_async('Foo')
      end
    end

    it 'uses the coordinator to find if a job exists' do
      expect(coordinator).to receive(:exists?).with('Foo', []).and_call_original

      expect(described_class.exists?('Foo')).to eq(true)
    end

    it 'uses the coordinator to find a job does not exist' do
      expect(coordinator).to receive(:exists?).with('Bar', []).and_call_original

      expect(described_class.exists?('Bar')).to eq(false)
    end
  end

  describe '.remaining', :redis do
    before do
      Sidekiq::Testing.disable! do
        MergeWorker.perform_async('Foo')
        MergeWorker.perform_in(10.minutes, 'Foo')

        5.times do
          BackgroundMigrationWorker.perform_async('Foo')
        end
        3.times do
          BackgroundMigrationWorker.perform_in(10.minutes, 'Foo')
        end
      end
    end

    it 'uses the coordinator to find the number of remaining jobs' do
      expect(coordinator).to receive(:remaining).and_call_original

      expect(described_class.remaining).to eq(8)
    end
  end
end
