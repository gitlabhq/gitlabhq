# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PoolRepositories::OrphanRecord, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:pool_repository) { create(:pool_repository, source_project: project) }

  describe '.from_pool' do
    let(:reasons) { :pool_no_source_project }
    let(:gitaly_relative_path) { nil }

    subject { described_class.from_pool(pool_repository, reasons, gitaly_relative_path) }

    context 'with a single reason' do
      it 'returns the expected hash with default relative_path' do
        is_expected.to eq(
          pool_id: pool_repository.id,
          disk_path: pool_repository.disk_path,
          relative_path: 'N/A',
          source_project_id: project.id,
          state: 'none',
          reason_codes: 'pool_no_source_project',
          reasons: 'Pool exists in Rails DB with no source_project_id set',
          member_projects_count: 1,
          shard_name: 'default'
        )
      end
    end

    context 'with multiple reasons' do
      let(:reasons) { [:pool_no_source_project, :pool_in_obsolete_state] }

      it 'joins reason codes and texts' do
        is_expected.to eq(
          pool_id: pool_repository.id,
          disk_path: pool_repository.disk_path,
          relative_path: 'N/A',
          source_project_id: project.id,
          state: 'none',
          reason_codes: 'pool_no_source_project|pool_in_obsolete_state',
          reasons: 'Pool exists in Rails DB with no source_project_id set; Pool marked as obsolete in Rails DB',
          member_projects_count: 1,
          shard_name: 'default'
        )
      end
    end

    context 'when gitaly_relative_path is provided' do
      let(:gitaly_relative_path) { '@pools/test.git' }

      it 'uses the provided relative_path' do
        is_expected.to eq(
          pool_id: pool_repository.id,
          disk_path: pool_repository.disk_path,
          relative_path: '@pools/test.git',
          source_project_id: project.id,
          state: 'none',
          reason_codes: 'pool_no_source_project',
          reasons: 'Pool exists in Rails DB with no source_project_id set',
          member_projects_count: 1,
          shard_name: 'default'
        )
      end
    end

    context 'with unknown reason' do
      it 'logs a warning and includes unknown reason in output' do
        expect(Gitlab::AppLogger).to receive(:warn).with(/Unknown orphan reason\(s\): unknown_reason/)

        result = described_class.from_pool(pool_repository, :unknown_reason)

        expect(result[:reason_codes]).to eq('unknown_reason')
        expect(result[:reasons]).to eq('Unknown reason: unknown_reason')
      end
    end

    context 'with mixed valid and invalid reasons' do
      it 'logs a warning listing only invalid reasons' do
        expect(Gitlab::AppLogger).to receive(:warn).with(/Unknown orphan reason\(s\): invalid_reason/)

        result = described_class.from_pool(pool_repository, [:pool_no_source_project, :invalid_reason])

        expect(result[:reason_codes]).to eq('pool_no_source_project|invalid_reason')
      end
    end
  end

  describe '.from_gitaly' do
    let(:pool_disk_path) { '@pools/4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce' }
    let(:storage_name) { 'default' }

    subject { described_class.from_gitaly(pool_disk_path, storage_name) }

    it 'returns the expected hash for a Gitaly-only pool' do
      is_expected.to eq(
        pool_id: 'N/A',
        disk_path: pool_disk_path,
        relative_path: "#{pool_disk_path}.git",
        source_project_id: nil,
        state: 'unknown',
        reason_codes: 'pool_on_gitaly_missing_db',
        reasons: 'Pool exists on Gitaly but missing from Rails DB',
        member_projects_count: 0,
        shard_name: 'default'
      )
    end
  end
end
