# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::RunnerBackoff::Communicator, :clean_gitlab_redis_shared_state, feature_category: :database do
  let(:migration) { instance_double(Gitlab::Database::Migration[2.1], name: 'TestClass') }

  describe '.execute_with_lock' do
    it 'delegates to a new instance object' do
      expect_next_instance_of(described_class, migration) do |communicator|
        expect(communicator).to receive(:execute_with_lock).and_call_original
      end

      expect { |b| described_class.execute_with_lock(migration, &b) }.to yield_control
    end
  end

  describe '.backoff_runner?' do
    subject { described_class.backoff_runner? }

    it { is_expected.to be_falsey }

    it 'is true when the lock is held' do
      described_class.execute_with_lock(migration) do
        is_expected.to be_truthy
      end
    end

    it 'reads from Redis' do
      recorder = RedisCommands::Recorder.new { subject }
      expect(recorder.log).to include(['exists', 'gitlab:exclusive_lease:gitlab/database/migration/runner/backoff'])
    end

    context 'with runner_migrations_backoff disabled' do
      before do
        stub_feature_flags(runner_migrations_backoff: false)
      end

      it 'is false when the lock is held' do
        described_class.execute_with_lock(migration) do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#execute_with_lock' do
    include ExclusiveLeaseHelpers

    let(:communicator) { described_class.new(migration) }
    let!(:lease) { stub_exclusive_lease(described_class::KEY, :uuid, timeout: described_class::EXPIRY) }

    it { expect { |b| communicator.execute_with_lock(&b) }.to yield_control }

    it 'raises error if it can not set the key' do
      expect(lease).to receive(:try_obtain).ordered.and_return(false)

      expect { communicator.execute_with_lock { 1 / 0 } }.to raise_error 'Could not set backoff key'
    end

    it 'removes the lease after executing the migration' do
      expect(lease).to receive(:try_obtain).ordered.and_return(true)
      expect(lease).to receive(:cancel).ordered.and_return(true)

      expect { communicator.execute_with_lock }.not_to raise_error
    end

    context 'with logger' do
      let(:logger) { instance_double(Gitlab::AppLogger) }
      let(:communicator) { described_class.new(migration, logger: logger) }

      it 'logs messages around execution' do
        expect(logger).to receive(:info).ordered
          .with({ class: 'TestClass', message: 'Executing migration with Runner backoff' })
        expect(logger).to receive(:info).ordered
          .with({ class: 'TestClass', message: 'Runner backoff key is set' })
        expect(logger).to receive(:info).ordered
          .with({ class: 'TestClass', message: 'Runner backoff key was removed' })

        communicator.execute_with_lock
      end
    end
  end
end
