# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration do
  describe '.queue' do
    it 'returns background migration worker queue' do
      expect(described_class.queue)
        .to eq BackgroundMigrationWorker.sidekiq_options['queue']
    end
  end

  describe '.steal' do
    context 'when there are enqueued jobs present' do
      let(:queue) do
        [double(args: ['Foo', [10, 20]], queue: described_class.queue)]
      end

      before do
        allow(Sidekiq::Queue).to receive(:new)
          .with(described_class.queue)
          .and_return(queue)
      end

      context 'when queue contains unprocessed jobs' do
        it 'steals jobs from a queue' do
          expect(queue[0]).to receive(:delete).and_return(true)

          expect(described_class).to receive(:perform)
            .with('Foo', [10, 20])

          described_class.steal('Foo')
        end

        it 'does not steal job that has already been taken' do
          expect(queue[0]).to receive(:delete).and_return(false)

          expect(described_class).not_to receive(:perform)

          described_class.steal('Foo')
        end

        it 'does not steal jobs for a different migration' do
          expect(described_class).not_to receive(:perform)

          expect(queue[0]).not_to receive(:delete)

          described_class.steal('Bar')
        end
      end

      context 'when one of the jobs raises an error' do
        let(:migration) { spy(:migration) }

        let(:queue) do
          [double(args: ['Foo', [10, 20]], queue: described_class.queue),
           double(args: ['Foo', [20, 30]], queue: described_class.queue)]
        end

        before do
          stub_const("#{described_class}::Foo", migration)

          allow(queue[0]).to receive(:delete).and_return(true)
          allow(queue[1]).to receive(:delete).and_return(true)
        end

        it 'enqueues the migration again and re-raises the error' do
          allow(migration).to receive(:perform).with(10, 20)
            .and_raise(Exception, 'Migration error').once

          expect(BackgroundMigrationWorker).to receive(:perform_async)
            .with('Foo', [10, 20]).once

          expect { described_class.steal('Foo') }.to raise_error(Exception)
        end
      end
    end

    context 'when there are scheduled jobs present', :sidekiq, :redis do
      it 'steals all jobs from the scheduled sets' do
        Sidekiq::Testing.disable! do
          BackgroundMigrationWorker.perform_in(10.minutes, 'Object')

          expect(Sidekiq::ScheduledSet.new).to be_one
          expect(described_class).to receive(:perform).with('Object', any_args)

          described_class.steal('Object')

          expect(Sidekiq::ScheduledSet.new).to be_none
        end
      end
    end

    context 'when there are enqueued and scheduled jobs present', :sidekiq, :redis do
      it 'steals from the scheduled sets queue first' do
        Sidekiq::Testing.disable! do
          expect(described_class).to receive(:perform)
            .with('Object', [1]).ordered
          expect(described_class).to receive(:perform)
            .with('Object', [2]).ordered

          BackgroundMigrationWorker.perform_async('Object', [2])
          BackgroundMigrationWorker.perform_in(10.minutes, 'Object', [1])

          described_class.steal('Object')
        end
      end
    end

    context 'when retry_dead_jobs is true', :sidekiq, :redis do
      let(:retry_queue) do
        [double(args: ['Object', [3]], queue: described_class.queue, delete: true)]
      end
      let(:dead_queue) do
        [double(args: ['Object', [4]], queue: described_class.queue, delete: true)]
      end

      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_queue)
        allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_queue)
      end

      it 'steals from the dead and retry queue' do
        Sidekiq::Testing.disable! do
          expect(described_class).to receive(:perform)
            .with('Object', [1]).ordered
          expect(described_class).to receive(:perform)
            .with('Object', [2]).ordered
          expect(described_class).to receive(:perform)
            .with('Object', [3]).ordered
          expect(described_class).to receive(:perform)
            .with('Object', [4]).ordered

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

    it 'performs a background migration' do
      expect(migration).to receive(:perform).with(10, 20).once

      described_class.perform('Foo', [10, 20])
    end

    context 'backward compatibility' do
      it 'performs a background migration for fully-qualified job classes' do
        expect(migration).to receive(:perform).with(10, 20).once
        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with(instance_of(StandardError), hash_including(:class_name))

        described_class.perform('Gitlab::BackgroundMigration::Foo', [10, 20])
      end
    end
  end

  describe '.exists?' do
    context 'when there are enqueued jobs present' do
      let(:queue) do
        [double(args: ['Foo', [10, 20]], queue: described_class.queue)]
      end

      before do
        allow(Sidekiq::Queue).to receive(:new)
          .with(described_class.queue)
          .and_return(queue)
      end

      it 'returns true if specific job exists' do
        expect(described_class.exists?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(described_class.exists?('Bar')).to eq(false)
      end
    end

    context 'when there are scheduled jobs present', :sidekiq, :redis do
      before do
        Sidekiq::Testing.disable! do
          BackgroundMigrationWorker.perform_in(10.minutes, 'Foo')

          expect(Sidekiq::ScheduledSet.new).to be_one
        end
      end

      after do
        Sidekiq::ScheduledSet.new.clear
      end

      it 'returns true if specific job exists' do
        expect(described_class.exists?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(described_class.exists?('Bar')).to eq(false)
      end
    end
  end

  describe '.dead_jobs?' do
    let(:queue) do
      [double(args: ['Foo', [10, 20]], queue: described_class.queue)]
    end

    context 'when there are dead jobs present' do
      before do
        allow(Sidekiq::DeadSet).to receive(:new).and_return(queue)
      end

      it 'returns true if specific job exists' do
        expect(described_class.dead_jobs?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(described_class.dead_jobs?('Bar')).to eq(false)
      end
    end
  end

  describe '.retrying_jobs?' do
    let(:queue) do
      [double(args: ['Foo', [10, 20]], queue: described_class.queue)]
    end

    context 'when there are dead jobs present' do
      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(queue)
      end

      it 'returns true if specific job exists' do
        expect(described_class.retrying_jobs?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(described_class.retrying_jobs?('Bar')).to eq(false)
      end
    end
  end
end
