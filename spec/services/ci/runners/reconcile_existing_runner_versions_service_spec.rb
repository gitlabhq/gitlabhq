# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ReconcileExistingRunnerVersionsService, '#execute' do
  subject(:execute) { described_class.new.execute }

  let_it_be(:runner_14_0_1) { create(:ci_runner, version: '14.0.1') }
  let_it_be(:runner_version_14_0_1) do
    create(:ci_runner_version, version: '14.0.1', status: :not_available)
  end

  before do
    stub_const('Ci::Runners::ReconcileExistingRunnerVersionsService::VERSION_BATCH_SIZE', 1)

    allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
      .to receive(:check_runner_upgrade_status)
      .and_return({ recommended: ::Gitlab::VersionInfo.new(14, 0, 2) })
  end

  context 'with runner with new version' do
    let!(:runner_14_0_2) { create(:ci_runner, version: '14.0.2') }
    let!(:runner_version_14_0_0) { create(:ci_runner_version, version: '14.0.0', status: :not_available) }
    let!(:runner_14_0_0) { create(:ci_runner, version: '14.0.0') }

    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .with('14.0.2')
        .and_return({ not_available: ::Gitlab::VersionInfo.new(14, 0, 2) })
        .once
    end

    it 'creates and updates expected ci_runner_versions entries', :aggregate_failures do
      expect(Ci::RunnerVersion).to receive(:insert_all)
        .ordered
        .with([{ version: '14.0.2' }], anything)
        .once
        .and_call_original

      result = nil
      expect { result = execute }
        .to change { runner_version_14_0_0.reload.status }.from('not_available').to('recommended')
        .and change { runner_version_14_0_1.reload.status }.from('not_available').to('recommended')
        .and change { ::Ci::RunnerVersion.find_by(version: '14.0.2')&.status }.from(nil).to('not_available')

      expect(result).to eq({
        status: :success,
        total_inserted: 1, # 14.0.2 is inserted
        total_updated: 3, # 14.0.0, 14.0.1 are updated, and newly inserted 14.0.2's status is calculated
        total_deleted: 0
      })
    end
  end

  context 'with orphan ci_runner_version' do
    let!(:runner_version_14_0_2) { create(:ci_runner_version, version: '14.0.2', status: :not_available) }

    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .and_return({ not_available: ::Gitlab::VersionInfo.new(14, 0, 2) })
    end

    it 'deletes orphan ci_runner_versions entry', :aggregate_failures do
      result = nil
      expect { result = execute }
        .to change { ::Ci::RunnerVersion.find_by_version('14.0.2')&.status }.from('not_available').to(nil)
        .and not_change { runner_version_14_0_1.reload.status }.from('not_available')

      expect(result).to eq({
        status: :success,
        total_inserted: 0,
        total_updated: 0,
        total_deleted: 1 # 14.0.2 is deleted
      })
    end
  end

  context 'with no runner version changes' do
    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .and_return({ not_available: ::Gitlab::VersionInfo.new(14, 0, 1) })
    end

    it 'does not modify ci_runner_versions entries', :aggregate_failures do
      result = nil
      expect { result = execute }.not_to change { runner_version_14_0_1.reload.status }.from('not_available')

      expect(result).to eq({
        status: :success,
        total_inserted: 0,
        total_updated: 0,
        total_deleted: 0
      })
    end
  end

  context 'with failing version check' do
    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .and_return({ error: ::Gitlab::VersionInfo.new(14, 0, 1) })
    end

    it 'makes no changes to ci_runner_versions', :aggregate_failures do
      result = nil
      expect { result = execute }.not_to change { runner_version_14_0_1.reload.status }.from('not_available')

      expect(result).to eq({
        status: :success,
        total_inserted: 0,
        total_updated: 0,
        total_deleted: 0
      })
    end
  end
end
