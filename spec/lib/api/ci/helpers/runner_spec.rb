# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Helpers::Runner, feature_category: :runner_core do
  let(:helper) do
    Class.new do
      include API::Ci::Helpers::Runner
      include Gitlab::RackLoadBalancingHelpers
    end.new
  end

  let(:env_hash) { {} }
  let(:request) { instance_double(Rack::Request, env: env_hash) }

  before do
    allow(helper).to receive(:request).and_return(request)
  end

  describe '#current_job', feature_category: :continuous_integration do
    let(:build) { create(:ci_build, :running) }

    it 'handles sticking of a build when a build ID is specified' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(Ci::Build.sticking)
        .to receive(:find_caught_up_replica)
        .with(:build, build.id, hash_id: false)

      helper.current_job

      stick_object = env_hash[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].first
      expect(stick_object[0]).to eq(Ci::Build.sticking)
      expect(stick_object[1]).to eq(:build)
      expect(stick_object[2]).to eq(build.id)
    end

    it 'does not handle sticking if no build ID was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Ci::Build.sticking)
        .not_to receive(:find_caught_up_replica)

      helper.current_job
    end

    it 'returns the build if one could be found' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(helper.current_job).to eq(build)
    end
  end

  describe '#current_runner', feature_category: :runner_core do
    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'handles sticking of a runner if a token is specified' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(Ci::Runner.sticking)
        .to receive(:find_caught_up_replica)
        .with(:runner, runner.token, hash_id: false)

      helper.current_runner

      stick_object = env_hash[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].first
      expect(stick_object[0]).to eq(Ci::Runner.sticking)
      expect(stick_object[1]).to eq(:runner)
      expect(stick_object[2]).to eq(runner.token)
    end

    it 'does not handle sticking if no token was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Ci::Runner.sticking)
        .not_to receive(:find_caught_up_replica)

      helper.current_runner
    end

    it 'returns the runner if one could be found' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(helper.current_runner).to eq(runner)
    end
  end

  describe '#current_runner_from_header', feature_category: :runner_core do
    let_it_be(:runner) { create(:ci_runner, token: 'foo') }
    let(:headers_response) { { API::Ci::Helpers::Runner::RUNNER_TOKEN_HEADER => runner.token } }

    subject(:current_runner_from_header) { helper.current_runner_from_header }

    before do
      allow(helper).to receive(:headers).and_return(headers_response)
    end

    it 'returns the runner' do
      allow(helper).to receive(:headers).and_return(API::Ci::Helpers::Runner::RUNNER_TOKEN_HEADER => runner.token)

      is_expected.to eq(runner)
    end

    it 'handles sticking of a runner' do
      expect(Ci::Runner.sticking)
        .to receive(:find_caught_up_replica)
        .with(:runner, runner.token, hash_id: false)

      current_runner_from_header

      stick_object = env_hash[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].first
      expect(stick_object[0]).to eq(Ci::Runner.sticking)
      expect(stick_object[1]).to eq(:runner)
      expect(stick_object[2]).to eq(runner.token)
    end

    context 'when no token is specified' do
      let(:headers_response) { {} }

      it 'does not handle sticking' do
        expect(Ci::Runner.sticking).not_to receive(:find_caught_up_replica)

        current_runner_from_header
      end
    end

    context 'when specified token is invalid' do
      let(:headers_response) { { API::Ci::Helpers::Runner::RUNNER_TOKEN_HEADER => 'invalid' } }

      it { is_expected.to be_nil }
    end
  end

  describe '#current_runner_manager', :freeze_time, feature_category: :fleet_visibility do
    let_it_be(:group) { create(:group) }

    let(:runner) { create(:ci_runner, :group, token: 'foo', groups: [group]) }

    subject(:current_runner_manager) { helper.current_runner_manager }

    context 'when runner manager already exists' do
      let!(:existing_runner_manager) do
        create(:ci_runner_machine, runner: runner, system_xid: 'bar', contacted_at: 1.hour.ago)
      end

      before do
        allow(helper).to receive(:params).and_return(token: runner.token, system_id: existing_runner_manager.system_xid)
      end

      it { is_expected.to eq(existing_runner_manager) }

      it 'does not update the contacted_at field' do
        expect(current_runner_manager.contacted_at).to eq 1.hour.ago
      end
    end

    context 'when runner manager cannot be found' do
      it 'creates a new runner manager', :aggregate_failures do
        allow(helper).to receive(:params).and_return(token: runner.token, system_id: 'new_system_id')

        expect { current_runner_manager }.to change { Ci::RunnerManager.count }.by(1)

        expect(current_runner_manager).not_to be_nil
        current_runner_manager.reload

        expect(current_runner_manager.system_xid).to eq('new_system_id')
        expect(current_runner_manager.contacted_at).to be_nil
        expect(current_runner_manager.runner).to eq(runner)
        expect(current_runner_manager.runner_type).to eq(runner.runner_type)

        # Verify that a second call doesn't raise an error
        expect { helper.current_runner_manager }.not_to raise_error
        expect(Ci::RunnerManager.count).to eq(1)
      end

      it 'creates a new <legacy> runner manager if system_id is not specified', :aggregate_failures do
        allow(helper).to receive(:params).and_return(token: runner.token)

        expect { current_runner_manager }.to change { Ci::RunnerManager.count }.by(1)

        expect(current_runner_manager).not_to be_nil
        expect(current_runner_manager.system_xid).to eq(::API::Ci::Helpers::Runner::LEGACY_SYSTEM_XID)
        expect(current_runner_manager.runner).to eq(runner)
        expect(current_runner_manager.runner_type).to eq(runner.runner_type)
      end
    end
  end

  describe '#track_runner_authentication', :prometheus, feature_category: :runner_core do
    subject { helper.track_runner_authentication }

    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'increments gitlab_ci_runner_authentication_success_total' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
      failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
      expect { subject }.to change { success_counter.get(runner_type: 'instance_type') }.by(1)
        .and not_change { success_counter.get(runner_type: 'project_type') }
        .and not_change { failure_counter.get }
    end

    it 'increments gitlab_ci_runner_authentication_failure_total' do
      allow(helper).to receive_messages(params: { token: 'invalid' }, headers: {})

      success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
      failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
      expect { subject }.to change { failure_counter.get }.by(1)
        .and not_change { success_counter.get(runner_type: 'instance_type') }
        .and not_change { success_counter.get(runner_type: 'project_type') }
    end

    context 'when token in headers' do
      it 'increments gitlab_ci_runner_authentication_success_total' do
        allow(helper).to receive_messages(
          headers: { API::Ci::Helpers::Runner::RUNNER_TOKEN_HEADER => runner.token },
          params: {}
        )

        success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
        failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
        expect { subject }.to change { success_counter.get(runner_type: 'instance_type') }.by(1)
          .and not_change { success_counter.get(runner_type: 'project_type') }
          .and not_change { failure_counter.get }
      end

      it 'increments gitlab_ci_runner_authentication_failure_total' do
        allow(helper).to receive_messages(
          headers: { API::Ci::Helpers::Runner::RUNNER_TOKEN_HEADER => 'invalid' },
          params: {}
        )

        success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
        failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
        expect { subject }.to change { failure_counter.get }.by(1)
          .and not_change { success_counter.get(runner_type: 'instance_type') }
          .and not_change { success_counter.get(runner_type: 'project_type') }
      end
    end
  end

  describe '#check_if_backoff_required!' do
    subject { helper.check_if_backoff_required! }

    let(:backoff_runner) { false }

    before do
      allow(Gitlab::Database::Migrations::RunnerBackoff::Communicator)
        .to receive(:backoff_runner?)
        .and_return(backoff_runner)
    end

    context 'when migrations are running' do
      let(:backoff_runner) { true }

      it 'denies requests' do
        expect(helper).to receive(:too_many_requests!)

        subject
      end
    end

    context 'when migrations are not running' do
      let(:backoff_runner) { false }

      it 'allows requests' do
        expect(helper).not_to receive(:too_many_requests!)

        subject
      end
    end

    describe '#job_router_enabled?' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }

      subject { helper.job_router_enabled?(runner) }

      context 'with instance runner' do
        let_it_be(:runner) { create(:ci_runner, :instance) }

        it { is_expected.to be true }

        context 'with feature flags' do
          where(:job_router, :job_router_instance_runners, :expected) do
            [
              [true,  true,  true],
              [true,  false, true],
              [false, true,  true],
              [false, false, false]
            ]
          end

          with_them do
            before do
              stub_feature_flags(
                job_router: job_router,
                job_router_instance_runners: job_router_instance_runners
              )
            end

            it { is_expected.to be expected }
          end
        end

        context 'and feature flag is enabled for specific runner only' do
          let(:specific_runner) { runner }

          before do
            stub_feature_flags(job_router_instance_runners: [specific_runner])
            stub_feature_flags(job_router: false)
          end

          it { is_expected.to be true }

          context 'when enabled for an unrelated runner' do
            let(:specific_runner) { create(:ci_runner, :instance) }

            it { is_expected.to be false }
          end
        end

        context 'and feature flag is enabled for single top-level group only' do
          before do
            stub_feature_flags(job_router_instance_runners: false)
            stub_feature_flags(job_router: [project.root_ancestor])
          end

          it { is_expected.to be false }
        end
      end

      context 'with group runner' do
        let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

        it { is_expected.to be true }

        context 'and feature flag is globally disabled' do
          before do
            stub_feature_flags(job_router: false)
          end

          it { is_expected.to be false }
        end

        context 'and feature flag is enabled for specific group only' do
          before do
            stub_feature_flags(job_router: [group])
          end

          it { is_expected.to be true }
        end
      end

      context 'with project runner' do
        let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

        it { is_expected.to be true }

        context 'and feature flag is globally disabled' do
          before do
            stub_feature_flags(job_router: false)
          end

          it { is_expected.to be false }
        end

        context 'and feature flag is enabled for group of project' do
          before do
            stub_feature_flags(job_router: [group])
          end

          it { is_expected.to be true }
        end

        context 'and feature flag is enabled for another project only' do
          let_it_be(:unrelated_project) { create(:project) }

          before do
            stub_feature_flags(job_router: [unrelated_project.root_ancestor])
          end

          it { is_expected.to be false }
        end
      end

      context 'with runner without owner' do
        let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

        before do
          allow(runner).to receive(:owner).and_return(nil)
        end

        it { is_expected.to be true }

        context 'when feature flag is enabled for single top-level group only' do
          before do
            stub_feature_flags(job_router_instance_runners: false)
            stub_feature_flags(job_router: [group])
          end

          it { is_expected.to be false }
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(job_router: false)
          end

          it { is_expected.to be false }
        end
      end
    end
  end
end
