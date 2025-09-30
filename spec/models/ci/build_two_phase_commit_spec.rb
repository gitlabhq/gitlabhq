# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Build, 'two_phase_job_commit runner feature support', :clean_gitlab_redis_cache,
  feature_category: :continuous_integration do
  let_it_be(:runner, freeze: true) { create(:ci_runner) }
  let_it_be(:runner_manager, freeze: true) { create(:ci_runner_machine, runner: runner) }
  let_it_be(:project, freeze: true) { create(:project, :repository) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:redis_klass) { Gitlab::Redis::SharedState }

  let(:build) { create(:ci_build, pipeline: pipeline) }

  describe '#waiting_for_runner_ack?' do
    subject { build.waiting_for_runner_ack? }

    context 'when build is not pending' do
      let(:build) { create(:ci_build, :running, pipeline: pipeline, runner: runner) }

      it { is_expected.to be false }
    end

    context 'when build is pending but has no runner' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

      it { is_expected.to be false }
    end

    context 'when build is pending with runner but no runner manager waiting for ack' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

      it { is_expected.to be false }
    end

    context 'when build is pending with runner and runner manager waiting for ack' do
      let(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

      it { is_expected.to be true }
    end

    context 'when build is in different states' do
      %i[created preparing manual scheduled success failed canceled skipped].each do |status|
        context "when build is #{status}" do
          let(:build) { create(:ci_build, status, pipeline: pipeline, runner: runner) }

          before do
            build.set_waiting_for_runner_ack(runner_manager.id)
          end

          it { is_expected.to be false }
        end
      end
    end

    context 'when allow_runner_job_acknowledgement feature flag is disabled' do
      before do
        stub_feature_flags(allow_runner_job_acknowledgement: false)
      end

      context 'when build is pending with runner and runner manager waiting for ack' do
        let(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

        it 'returns true because Redis entry exists (edge case fix)' do
          is_expected.to be true
        end
      end

      context 'when build is pending with runner but no runner manager waiting for ack' do
        let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it { is_expected.to be false }
      end
    end
  end

  describe '#set_waiting_for_runner_ack' do
    let(:runner_manager_id) { 123 }

    it 'stores the runner manager ID in Redis with expiry' do
      build.set_waiting_for_runner_ack(runner_manager_id)

      # Verify the value is stored
      expect(build.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)

      # Verify the key has an expiry time set
      ttl = runner_build_ack_queue_key_ttl
      expect(ttl).to be > 0
      expect(ttl).to be <= described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME
    end

    it 'uses the correct expiry time' do
      expect(described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME).to eq(2.minutes)
    end
  end

  describe '#cancel_wait_for_runner_ack' do
    let(:runner_manager_id) { 123 }

    before do
      build.set_waiting_for_runner_ack(runner_manager_id)
    end

    it 'removes the runner manager ID from Redis' do
      expect do
        build.cancel_wait_for_runner_ack
      end.to change { build.runner_manager_id_waiting_for_ack }.from(runner_manager_id).to(nil)
    end
  end

  describe '#runner_manager_id_waiting_for_ack' do
    subject(:runner_manager_id_waiting_for_ack) { build.runner_manager_id_waiting_for_ack }

    context 'when no runner manager is waiting for ack' do
      it { is_expected.to be_nil }
    end

    context 'when a runner manager is waiting for ack' do
      let(:runner_manager_id) { 456 }

      before do
        build.set_waiting_for_runner_ack(runner_manager_id)
      end

      it { is_expected.to eq(runner_manager_id) }
    end

    context 'when the Redis key has expired' do
      let(:runner_manager_id) { 789 }

      before do
        build.set_waiting_for_runner_ack(runner_manager_id)

        # Simulate expiry by manually deleting the key
        redis_klass.with { |redis| redis.del(runner_build_ack_queue_key) }
      end

      it { is_expected.to be_nil }
    end

    context 'when allow_runner_job_acknowledgement feature flag is disabled' do
      before do
        stub_feature_flags(allow_runner_job_acknowledgement: false)
      end

      context 'when no runner manager is waiting for ack' do
        it { is_expected.to be_nil }
      end

      context 'when a runner manager is waiting for ack' do
        let(:runner_manager_id) { 456 }

        before do
          build.set_waiting_for_runner_ack(runner_manager_id)
        end

        it 'returns the value regardless of feature flag state' do
          # Verify Redis has the value
          expect(redis_klass.with { |redis| redis.get(runner_build_ack_queue_key)&.to_i })
            .to eq(runner_manager_id)

          expect(runner_manager_id_waiting_for_ack).to eq(runner_manager_id)
        end
      end
    end
  end

  describe 'state transition from pending to running' do
    context 'when build is waiting for runner ack' do
      let(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

      it 'resets waiting for runner ack on transition to running' do
        expect(build).to receive(:cancel_wait_for_runner_ack).and_call_original

        expect { build.run! }.to change { build.runner_manager_id_waiting_for_ack }.to(nil)
      end
    end

    context 'when build is not waiting for runner ack' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

      it 'still calls reset_waiting_for_runner_ack' do
        expect(build).to receive(:cancel_wait_for_runner_ack).and_call_original

        build.run!
      end
    end
  end

  describe 'integration with Redis' do
    let(:runner_manager_id) { 999 }

    it 'can set, get, and delete values from Redis' do
      # Initially no value
      expect(build.runner_manager_id_waiting_for_ack).to be_nil

      # Set a value
      build.set_waiting_for_runner_ack(runner_manager_id)
      expect(build.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)

      # Reset the value
      build.cancel_wait_for_runner_ack
      expect(build.runner_manager_id_waiting_for_ack).to be_nil
    end

    it 'handles string to integer conversion correctly' do
      build.set_waiting_for_runner_ack(runner_manager_id)

      # Verify that the value is stored as string but returned as integer
      redis_klass.with do |redis|
        stored_value = redis.get(runner_build_ack_queue_key)
        expect(stored_value).to eq(runner_manager_id.to_s)
      end

      expect(build.runner_manager_id_waiting_for_ack).to eq(runner_manager_id)
    end

    it 'handles nil and zero values correctly' do
      expect(build.runner_manager_id_waiting_for_ack).to be_nil

      # Test with nil (should not set anything)
      build.set_waiting_for_runner_ack(nil)
      expect(build.runner_manager_id_waiting_for_ack).to be_nil

      # Test with zero
      build.set_waiting_for_runner_ack(0)
      expect(build.runner_manager_id_waiting_for_ack).to be_zero
    end

    it 'does not overwrite existing values' do
      build.set_waiting_for_runner_ack(100)
      expect(build.runner_manager_id_waiting_for_ack).to eq(100)

      expect { build.set_waiting_for_runner_ack(200) }
        .not_to change { build.runner_manager_id_waiting_for_ack }.from(100)
    end
  end

  describe '#supported_runner?' do
    subject(:supported_runner) { build.supported_runner?(features) }

    context 'when runner supports two_phase_job_commit' do
      let(:features) { { two_phase_job_commit: true } }

      it 'returns true for runners with two_phase_job_commit feature' do
        is_expected.to be true
      end
    end

    context 'when runner does not support two_phase_job_commit' do
      let(:features) { { other_feature: true } }

      it 'returns true for runners without two_phase_job_commit feature' do
        # two_phase_job_commit is not a required feature, so builds should work
        # with both old and new runners
        is_expected.to be true
      end
    end

    context 'when features is nil' do
      let(:features) { nil }

      it 'returns true for legacy runners' do
        is_expected.to be true
      end
    end

    context 'when features is empty' do
      let(:features) { {} }

      it 'returns true for runners with no features' do
        is_expected.to be true
      end
    end

    context 'with specific runner feature requirements' do
      # This test ensures that two_phase_job_commit doesn't interfere with
      # existing runner feature requirements
      let(:build) do
        create(:ci_build, pipeline: pipeline, options: {
          artifacts: {
            reports: {
              junit: 'test-results.xml'
            }
          }
        })
      end

      context 'when runner supports both required features and two_phase_job_commit' do
        let(:features) do
          {
            upload_multiple_artifacts: true,
            two_phase_job_commit: true
          }
        end

        it 'returns true' do
          is_expected.to be true
        end
      end

      context 'when runner supports two_phase_job_commit but not required features' do
        let(:features) do
          {
            two_phase_job_commit: true
            # missing upload_multiple_artifacts
          }
        end

        it 'returns false due to missing required feature' do
          is_expected.to be false
        end
      end
    end
  end

  describe 'RUNNER_ACK_QUEUE_EXPIRY_TIME constant' do
    it 'is set to 2 minutes' do
      expect(described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME).to eq(2.minutes)
    end
  end

  describe 'edge cases' do
    context 'when Redis is unavailable' do
      let(:runner_manager_id) { 123 }

      before do
        allow(redis_klass).to receive(:with).and_raise(Redis::CannotConnectError)
      end

      it 'raises error from set_waiting_for_runner_ack' do
        expect { build.set_waiting_for_runner_ack(runner_manager_id) }.to raise_error(Redis::CannotConnectError)
      end

      it 'raises error from runner_manager_id_waiting_for_ack' do
        expect { build.cancel_wait_for_runner_ack }.to raise_error(Redis::CannotConnectError)
      end

      it 'raises error from runner_manager_id_waiting_for_ack' do
        expect { build.runner_manager_id_waiting_for_ack }.to raise_error(Redis::CannotConnectError)
      end
    end
  end

  describe '#heartbeat_runner_ack_wait' do
    let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

    subject(:heartbeat_runner_ack_wait) { build.heartbeat_runner_ack_wait(runner_manager_id) }

    context 'when runner_manager_id does not exist' do
      let(:runner_manager_id) { non_existing_record_id }

      it 'does not create new Redis cache entry' do
        expect { heartbeat_runner_ack_wait }
          .to not_change { runner_build_ack_queue_key_ttl }.from(-2)
          .and not_change { build.runner_manager_id_waiting_for_ack }.from(nil)

        expect(heartbeat_runner_ack_wait).to be_falsey
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

      it 'updates the Redis cache entry with new TTL' do
        redis_klass.with do |redis|
          expect(redis).to receive(:set)
            .with(runner_build_ack_queue_key, runner_manager_id,
              ex: described_class::RUNNER_ACK_QUEUE_EXPIRY_TIME, xx: true)
            .and_call_original
        end

        expect { heartbeat_runner_ack_wait }
          .to change { runner_build_ack_queue_key_ttl }.by_at_least(10)
          .and not_change { build.runner_manager_id_waiting_for_ack }.from(runner_manager_id)

        expect(heartbeat_runner_ack_wait).to be_truthy
      end

      context 'and runner_manager_id does not match existing cache entry' do
        it 'does not create new Redis cache entry and returns false' do
          expect { build.heartbeat_runner_ack_wait(non_existing_record_id) }
            .to not_change { runner_build_ack_queue_key_ttl > 0 }.from(true)
            .and not_change { build.runner_manager_id_waiting_for_ack }.from(runner_manager_id)

          expect(build.heartbeat_runner_ack_wait(non_existing_record_id)).to be_falsey
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

  private

  def runner_build_ack_queue_key
    build.send(:runner_build_ack_queue_key)
  end

  def runner_build_ack_queue_key_ttl
    redis_klass.with { |redis| redis.ttl(runner_build_ack_queue_key) }
  end
end
