# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Helpers::Runner, feature_category: :runner do
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
        .with(:build, build.id)

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

  describe '#current_runner', feature_category: :runner do
    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'handles sticking of a runner if a token is specified' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(Ci::Runner.sticking)
        .to receive(:find_caught_up_replica)
        .with(:runner, runner.token)

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

      # TODO Remove when https://gitlab.com/gitlab-org/gitlab/-/issues/503749 is merged
      context 'with nil sharding_key_id' do
        let!(:existing_runner_manager) do
          Ci::ApplicationRecord.connection.execute <<~SQL
            ALTER TABLE ci_runner_machines DISABLE TRIGGER ALL;

            INSERT INTO ci_runner_machines
               (created_at, updated_at, contacted_at, runner_id, runner_type, system_xid, sharding_key_id)
              VALUES(NOW(), NOW(), '#{1.hour.ago}', #{runner.id}, 2, 'bar', NULL);

            ALTER TABLE ci_runner_machines ENABLE TRIGGER ALL;
          SQL

          Ci::RunnerManager.for_runner(runner).with_system_xid('bar').first
        end

        it 'reuses existing runner manager', :aggregate_failures do
          expect { current_runner_manager }.not_to raise_error

          expect(current_runner_manager).not_to be_nil
          expect(current_runner_manager).to eq existing_runner_manager
          expect(current_runner_manager.reload.contacted_at).to eq 1.hour.ago
          expect(current_runner_manager.runner_type).to eq runner.runner_type
          expect(current_runner_manager.sharding_key_id).to be_nil
        end
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
        expect(current_runner_manager.sharding_key_id).to eq(runner.sharding_key_id)

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
        expect(current_runner_manager.sharding_key_id).to eq(runner.sharding_key_id)
      end
    end

    context 'when project runner is missing sharding_key_id' do
      let(:runner) { Ci::Runner.project_type.last }
      let(:connection) { Ci::Runner.connection }

      before do
        connection.execute(<<~SQL)
          ALTER TABLE ci_runners DISABLE TRIGGER ALL;

          INSERT INTO ci_runners(created_at, runner_type, token, sharding_key_id) VALUES(NOW(), 3, 'foo', NULL);

          ALTER TABLE ci_runners ENABLE TRIGGER ALL;
        SQL
      end

      it 'fails to create a new runner manager', :aggregate_failures do
        allow(helper).to receive(:params).and_return(token: runner.token, system_id: 'new_system_id')
        expect(helper.current_runner).to eq(runner)

        expect { current_runner_manager }.to raise_error described_class::UnknownRunnerOwnerError
      end

      # TODO: Remove once https://gitlab.com/gitlab-org/gitlab/-/issues/516929 is closed.
      context 'with reject_orphaned_runners FF disabled' do
        before do
          stub_feature_flags(reject_orphaned_runners: false)
        end

        it 'fails to create a new runner manager', :aggregate_failures do
          allow(helper).to receive(:params).and_return(token: runner.token, system_id: 'new_system_id')
          expect(helper.current_runner).to eq(runner)

          expect { current_runner_manager }.to raise_error described_class::UnknownRunnerOwnerError
        end
      end
    end
  end

  describe '#track_runner_authentication', :prometheus, feature_category: :runner do
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
      allow(helper).to receive(:params).and_return(token: 'invalid')

      success_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_success_counter
      failure_counter = ::Gitlab::Ci::Runner::Metrics.runner_authentication_failure_counter
      expect { subject }.to change { failure_counter.get }.by(1)
        .and not_change { success_counter.get(runner_type: 'instance_type') }
        .and not_change { success_counter.get(runner_type: 'project_type') }
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
  end
end
