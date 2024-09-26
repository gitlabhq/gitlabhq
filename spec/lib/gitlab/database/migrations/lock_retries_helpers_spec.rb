# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::LockRetriesHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe '#with_lock_retries' do
    let(:buffer) { StringIO.new }
    let(:in_memory_logger) { Gitlab::JsonLogger.new(buffer) }
    let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

    it 'sets the migration class name in the logs' do
      model.with_lock_retries(env: env, logger: in_memory_logger) {}

      buffer.rewind
      expect(buffer.read).to include("\"class\":\"#{model.class}\"")
    end

    where(raise_on_exhaustion: [true, false])

    with_them do
      it 'sets raise_on_exhaustion as requested' do
        with_lock_retries = double
        expect(Gitlab::Database::WithLockRetries).to receive(:new).and_return(with_lock_retries)
        expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: raise_on_exhaustion)

        model.with_lock_retries(env: env, logger: in_memory_logger, raise_on_exhaustion: raise_on_exhaustion) {}
      end
    end

    it 'raises on exhaustion by default' do
      with_lock_retries = double
      expect(Gitlab::Database::WithLockRetries).to receive(:new).and_return(with_lock_retries)
      expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: true)

      model.with_lock_retries(env: env, logger: in_memory_logger) {}
    end

    it 'defaults to allowing subtransactions' do
      with_lock_retries = double

      expect(Gitlab::Database::WithLockRetries)
        .to receive(:new).with(hash_including(allow_savepoints: true)).and_return(with_lock_retries)
      expect(with_lock_retries).to receive(:run).with(raise_on_exhaustion: true)

      model.with_lock_retries(env: env, logger: in_memory_logger) {}
    end
  end
end
