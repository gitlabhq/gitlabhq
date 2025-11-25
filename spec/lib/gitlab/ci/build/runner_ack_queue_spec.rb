# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::RunnerAckQueue, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  let_it_be(:runner, freeze: true) { create(:ci_runner) }
  let_it_be(:project, freeze: true) { create(:project, :repository) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:redis_klass) { Gitlab::Redis::SharedState }

  let(:build) { create(:ci_build, :pending, pipeline: pipeline) }
  let(:runner_ack_queue) { described_class.new(build) }

  describe '#set_waiting_for_runner_ack' do
    let(:runner_manager_id) { 123 }

    subject(:set_waiting_for_runner_ack) { runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id) }

    it 'stores the runner manager ID in Redis with expiry' do
      set_waiting_for_runner_ack

      # Verify the value is stored
      expect(build.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)

      # Verify the key has an expiry time set
      ttl = runner_build_ack_queue_key_ttl
      expect(ttl).to be > 0
      expect(ttl).to be <= described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME
    end

    context 'when runner_manager_id is nil' do
      let(:runner_manager_id) { nil }

      it 'does not store anything in Redis' do
        set_waiting_for_runner_ack

        expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil
      end
    end

    context 'when runner_manager_id is empty string' do
      let(:runner_manager_id) { '' }

      it 'does not store anything in Redis' do
        set_waiting_for_runner_ack

        expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil
      end
    end

    it 'does not overwrite existing values' do
      runner_ack_queue.set_waiting_for_runner_ack(100)
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to eq(100)

      expect { runner_ack_queue.set_waiting_for_runner_ack(200) }
        .not_to change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(100)
    end
  end

  describe 'RUNNER_ACK_QUEUE_EXPIRY_TIME constant' do
    it 'is set to 2 minutes' do
      expect(described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME).to eq(2.minutes)
    end
  end

  describe '#cancel_wait_for_runner_ack' do
    let(:runner_manager_id) { 123 }

    subject(:cancel_wait_for_runner_ack) { runner_ack_queue.cancel_wait_for_runner_ack }

    context 'when runner manager is waiting for ack' do
      before do
        runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)
      end

      it 'atomically retrieves and removes the runner manager ID from Redis' do
        expect(cancel_wait_for_runner_ack).to eq(runner_manager_id.to_s)
        expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil
      end

      it 'removes the runner manager ID from Redis' do
        expect do
          cancel_wait_for_runner_ack
        end.to change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(runner_manager_id).to(nil)
      end
    end

    context 'when no runner manager is waiting for ack' do
      it { is_expected.to be_nil }
    end
  end

  describe '#runner_manager_id_waiting_for_ack' do
    subject(:runner_manager_id_waiting_for_ack) { runner_ack_queue.runner_manager_id_waiting_for_ack }

    context 'when no runner manager is waiting for ack' do
      it { is_expected.to be_nil }
    end

    context 'when a runner manager is waiting for ack' do
      let(:runner_manager_id) { 456 }

      before do
        runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)
      end

      it { is_expected.to eq(runner_manager_id) }
    end

    context 'when the Redis key has expired' do
      let(:runner_manager_id) { 789 }

      before do
        runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)

        # Simulate expiry by manually deleting the key
        redis_klass.with { |redis| redis.del(runner_build_ack_queue_key) }
      end

      it { is_expected.to be_nil }
    end

    it 'handles string to integer conversion correctly' do
      runner_manager_id = 999
      runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)

      # Verify that the value is stored as string but returned as integer
      redis_klass.with do |redis|
        stored_value = redis.get(runner_build_ack_queue_key)
        expect(stored_value).to eq(runner_manager_id.to_s)
      end

      expect(runner_manager_id_waiting_for_ack).to eq(runner_manager_id)
    end

    it 'handles zero values correctly' do
      runner_ack_queue.set_waiting_for_runner_ack(0)
      expect(runner_manager_id_waiting_for_ack).to be_zero
    end
  end

  describe '#heartbeat_runner_ack_wait' do
    subject(:heartbeat_runner_ack_wait) { runner_ack_queue.heartbeat_runner_ack_wait(runner_manager_id) }

    context 'when runner_manager_id does not exist' do
      let(:runner_manager_id) { non_existing_record_id }

      it 'does not create new Redis cache entry and returns nil' do
        expect { heartbeat_runner_ack_wait }
          .to not_change { runner_build_ack_queue_key_ttl }.from(-2)
          .and not_change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(nil)

        expect(heartbeat_runner_ack_wait).to be_nil
      end
    end

    context 'when runner_manager_id is present' do
      let(:runner_manager_id) { 123 }

      before do
        redis_klass.with do |redis|
          redis.set(runner_build_ack_queue_key, runner_manager_id,
            ex: described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME - 10, nx: true)
        end
      end

      it 'updates the Redis cache entry with new TTL and returns true' do
        redis_klass.with do |redis|
          expect(redis).to receive(:set)
            .with(runner_build_ack_queue_key, runner_manager_id,
              ex: described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME, xx: true)
            .and_call_original
        end

        expect { heartbeat_runner_ack_wait }
          .to change { runner_build_ack_queue_key_ttl }.by_at_least(10)
          .and not_change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(runner_manager_id)

        expect(heartbeat_runner_ack_wait).to be true
      end

      context 'and runner_manager_id does not match existing cache entry' do
        it 'does not create new Redis cache entry and returns nil' do
          expect { runner_ack_queue.heartbeat_runner_ack_wait(non_existing_record_id) }
            .to not_change { runner_build_ack_queue_key_ttl > 0 }.from(true)
            .and not_change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(runner_manager_id)

          expect(runner_ack_queue.heartbeat_runner_ack_wait(non_existing_record_id)).to be_nil
        end
      end

      context 'when Redis operation fails' do
        before do
          redis_klass.with do |redis|
            allow(redis).to receive(:set).and_raise(Redis::BaseError, 'Connection failed')
          end
        end

        it 'raises error' do
          expect { heartbeat_runner_ack_wait }.to raise_error(Redis::BaseError)
        end
      end
    end

    context 'when runner_manager_id is nil' do
      let(:runner_manager_id) { nil }

      it 'does not update Redis cache' do
        redis_klass.with do |redis|
          expect(redis).not_to receive(:set)
        end

        heartbeat_runner_ack_wait
      end
    end

    context 'when runner_manager_id is empty string' do
      let(:runner_manager_id) { '' }

      it 'does not update Redis cache' do
        redis_klass.with do |redis|
          expect(redis).not_to receive(:set)
        end

        heartbeat_runner_ack_wait
      end
    end
  end

  describe 'integration with Redis' do
    let(:runner_manager_id) { 999 }

    it 'can set, get, and delete values from Redis' do
      # Initially no value
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil

      # Set a value
      runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)

      # Reset the value
      runner_ack_queue.cancel_wait_for_runner_ack
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil
    end

    it 'handles string to integer conversion correctly' do
      runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id)

      # Verify that the value is stored as string but returned as integer
      redis_klass.with do |redis|
        stored_value = redis.get(runner_build_ack_queue_key)
        expect(stored_value).to eq(runner_manager_id.to_s)
      end

      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)
    end

    it 'handles nil and zero values correctly' do
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil

      # Test with nil (should not set anything)
      runner_ack_queue.set_waiting_for_runner_ack(nil)
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_nil

      # Test with zero
      runner_ack_queue.set_waiting_for_runner_ack(0)
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to be_zero
    end

    it 'does not overwrite existing values' do
      runner_ack_queue.set_waiting_for_runner_ack(100)
      expect(runner_ack_queue.runner_manager_id_waiting_for_ack).to eq(100)

      expect { runner_ack_queue.set_waiting_for_runner_ack(200) }
        .not_to change { runner_ack_queue.runner_manager_id_waiting_for_ack }.from(100)
    end
  end

  describe 'edge cases' do
    context 'when Redis is unavailable' do
      let(:runner_manager_id) { 123 }

      before do
        allow(redis_klass).to receive(:with).and_raise(Redis::CannotConnectError)
      end

      it 'raises error from set_waiting_for_runner_ack' do
        expect { runner_ack_queue.set_waiting_for_runner_ack(runner_manager_id) }
          .to raise_error(Redis::CannotConnectError)
      end

      it 'raises error from cancel_wait_for_runner_ack' do
        expect { runner_ack_queue.cancel_wait_for_runner_ack }.to raise_error(Redis::CannotConnectError)
      end

      it 'raises error from runner_manager_id_waiting_for_ack' do
        expect { runner_ack_queue.runner_manager_id_waiting_for_ack }.to raise_error(Redis::CannotConnectError)
      end
    end
  end

  private

  def runner_build_ack_queue_key
    runner_ack_queue.redis_key
  end

  def runner_build_ack_queue_key_ttl
    redis_klass.with { |redis| redis.ttl(runner_build_ack_queue_key) }
  end
end
