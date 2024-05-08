# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ReconcileExistingRunnerVersionsService, '#execute', feature_category: :fleet_visibility do
  include RunnerReleasesHelper

  subject(:execute) { described_class.new.execute }

  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:runner_manager_14_0_1) { create(:ci_runner_machine, runner: runner, version: '14.0.1') }
  let_it_be(:runner_version_14_0_1) { create(:ci_runner_version, version: '14.0.1', status: :unavailable) }

  context 'with RunnerUpgradeCheck recommending 14.0.2' do
    let(:upgrade_check) { instance_double(::Gitlab::Ci::RunnerUpgradeCheck) }

    before do
      stub_const('Ci::Runners::ReconcileExistingRunnerVersionsService::VERSION_BATCH_SIZE', 1)

      allow(::Gitlab::Ci::RunnerUpgradeCheck).to receive(:new).and_return(upgrade_check).once
    end

    context 'with runner with new version' do
      let!(:runner_manager_14_0_2) { create(:ci_runner_machine, runner: runner, version: '14.0.2') }
      let!(:runner_manager_14_0_0) { create(:ci_runner_machine, runner: runner, version: '14.0.0') }
      let!(:runner_version_14_0_0) { create(:ci_runner_version, version: '14.0.0', status: :unavailable) }

      before do
        allow(upgrade_check).to receive(:check_runner_upgrade_suggestion)
          .and_return([::Gitlab::VersionInfo.new(14, 0, 2), :recommended])
        allow(upgrade_check).to receive(:check_runner_upgrade_suggestion)
          .with('14.0.2')
          .and_return([::Gitlab::VersionInfo.new(14, 0, 2), :unavailable])
          .once
      end

      it 'creates and updates expected ci_runner_versions entries', :aggregate_failures do
        expect(Ci::RunnerVersion).to receive(:insert_all)
          .ordered
          .with([{ version: '14.0.2' }], anything)
          .once
          .and_call_original

        expect { execute }
          .to change { runner_version_14_0_0.reload.status }.from('unavailable').to('recommended')
          .and change { runner_version_14_0_1.reload.status }.from('unavailable').to('recommended')
          .and change { ::Ci::RunnerVersion.find_by(version: '14.0.2')&.status }.from(nil).to('unavailable')

        expect(execute).to be_success
        expect(execute.payload).to eq({
          total_inserted: 1, # 14.0.2 is inserted
          total_updated: 3, # 14.0.0, 14.0.1 are updated, and newly inserted 14.0.2's status is calculated
          total_deleted: 0
        })
      end
    end

    context 'with orphan ci_runner_version' do
      let!(:runner_version_14_0_2) do
        create(:ci_runner_version, version: '14.0.2', status: :unavailable)
      end

      before do
        allow(upgrade_check).to receive(:check_runner_upgrade_suggestion)
          .and_return([::Gitlab::VersionInfo.new(14, 0, 2), :unavailable])
      end

      it 'deletes orphan ci_runner_versions entry', :aggregate_failures do
        expect { execute }
          .to change { ::Ci::RunnerVersion.find_by_version('14.0.2')&.status }.from('unavailable').to(nil)
          .and not_change { runner_version_14_0_1.reload.status }.from('unavailable')

        expect(execute).to be_success
        expect(execute.payload).to eq({
          total_inserted: 0,
          total_updated: 0,
          total_deleted: 1 # 14.0.2 is deleted
        })
      end
    end

    context 'with no runner version changes' do
      before do
        allow(upgrade_check).to receive(:check_runner_upgrade_suggestion)
          .and_return([::Gitlab::VersionInfo.new(14, 0, 1), :unavailable])
      end

      it 'does not modify ci_runner_versions entries', :aggregate_failures do
        expect { execute }.not_to change { runner_version_14_0_1.reload.status }.from('unavailable')

        expect(execute).to be_success
        expect(execute.payload).to eq({
          total_inserted: 0,
          total_updated: 0,
          total_deleted: 0
        })
      end
    end

    context 'with failing version check' do
      before do
        allow(upgrade_check).to receive(:check_runner_upgrade_suggestion)
          .and_return([::Gitlab::VersionInfo.new(14, 0, 1), :error])
      end

      it 'makes no changes to ci_runner_versions', :aggregate_failures do
        expect { execute }.not_to change { runner_version_14_0_1.reload.status }.from('unavailable')

        expect(execute).to be_success
        expect(execute.payload).to eq({
          total_inserted: 0,
          total_updated: 0,
          total_deleted: 0
        })
      end
    end
  end

  context 'integration testing with Gitlab::Ci::RunnerUpgradeCheck' do
    before do
      stub_runner_releases(%w[14.0.0 14.0.1])
    end

    it 'does not modify ci_runner_versions entries', :aggregate_failures do
      expect { execute }.not_to change { runner_version_14_0_1.reload.status }.from('unavailable')

      expect(execute).to be_success
      expect(execute.payload).to eq({
        total_inserted: 0,
        total_updated: 0,
        total_deleted: 0
      })
    end
  end
end
