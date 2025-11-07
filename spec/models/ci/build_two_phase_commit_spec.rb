# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Build, 'two_phase_job_commit runner feature support', :clean_gitlab_redis_cache,
  feature_category: :continuous_integration do
  let_it_be(:runner, freeze: true) { create(:ci_runner) }
  let_it_be(:runner_manager, freeze: true) { create(:ci_runner_machine, runner: runner) }
  let_it_be(:project, freeze: true) { create(:project, :repository) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline) }
  let(:runner_ack_queue) { build.send(:runner_ack_queue) }

  describe '#runner_ack_wait_status' do
    subject { build.runner_ack_wait_status }

    context 'when build is not pending' do
      let(:build) { create(:ci_build, :running, pipeline: pipeline, runner: runner) }

      it { is_expected.to eq :not_waiting }
    end

    context 'when build is pending but has no runner' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

      it { is_expected.to eq :not_waiting }
    end

    context 'when build is pending with runner but no runner manager waiting for ack' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

      it { is_expected.to eq :wait_expired }
    end

    context 'when build is pending with runner and runner manager waiting for ack' do
      let(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

      it { is_expected.to eq :waiting }
    end

    context 'when build is in different states' do
      %i[created preparing manual scheduled success failed canceled skipped].each do |status|
        context "when build is #{status}" do
          let(:build) { create(:ci_build, status, pipeline: pipeline, runner: runner) }

          before do
            build.set_waiting_for_runner_ack(runner_manager.id)
          end

          it { is_expected.to eq :not_waiting }
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
          is_expected.to eq :waiting
        end
      end

      context 'when build is pending with runner but no runner manager waiting for ack' do
        let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

        it { is_expected.to eq :wait_expired }
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:set_waiting_for_runner_ack).to(:runner_ack_queue) }
    it { is_expected.to delegate_method(:cancel_wait_for_runner_ack).to(:runner_ack_queue) }
    it { is_expected.to delegate_method(:runner_manager_id_waiting_for_ack).to(:runner_ack_queue) }
    it { is_expected.to delegate_method(:heartbeat_runner_ack_wait).to(:runner_ack_queue) }
  end

  describe '#runner_ack_queue' do
    it 'returns a Gitlab::Ci::Build::RunnerAckQueue instance' do
      expect(runner_ack_queue).to be_a(Gitlab::Ci::Build::RunnerAckQueue)
    end

    it 'memoizes the instance' do
      expect(runner_ack_queue).to be(build.send(:runner_ack_queue))
    end
  end

  describe 'state transition from pending to running' do
    context 'when build is waiting for runner ack' do
      it 'resets waiting for runner ack on transition to running' do
        expect(runner_ack_queue).to receive(:cancel_wait_for_runner_ack).and_call_original

        expect { build.run! }.to change { runner_ack_queue.runner_manager_id_waiting_for_ack }.to(nil)
      end
    end

    context 'when build is not waiting for runner ack' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline, runner: runner) }

      it 'still calls reset_waiting_for_runner_ack' do
        expect(runner_ack_queue).to receive(:cancel_wait_for_runner_ack).and_call_original

        build.run!
      end
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
end
