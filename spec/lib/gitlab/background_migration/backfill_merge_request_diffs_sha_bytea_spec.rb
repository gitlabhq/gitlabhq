# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestDiffsShaBytea,
  feature_category: :code_review_workflow do
  let(:organizations)       { table(:organizations) }
  let(:namespaces)          { table(:namespaces) }
  let(:projects)            { table(:projects) }
  let(:merge_requests)      { table(:merge_requests) }
  let(:merge_request_diffs) { table(:merge_request_diffs) }

  let(:base_sha)  { 'a' * 40 }
  let(:start_sha) { 'b' * 40 }
  let(:head_sha)  { 'c' * 40 }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let!(:namespace) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project', path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:merge_request) do
    merge_requests.create!(
      target_project_id: project.id,
      source_branch: 'feature',
      target_branch: 'master'
    )
  end

  # Suspend the bidirectional sync trigger so we can construct the pre-deploy
  # state where varchar columns are populated but bytea columns are NULL.
  around do |example|
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE merge_request_diffs DISABLE TRIGGER merge_request_diffs_sync_bytea_sha_on_insert;
      ALTER TABLE merge_request_diffs DISABLE TRIGGER merge_request_diffs_sync_bytea_sha_on_update;
    SQL
    example.run
  ensure
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE merge_request_diffs ENABLE TRIGGER merge_request_diffs_sync_bytea_sha_on_insert;
      ALTER TABLE merge_request_diffs ENABLE TRIGGER merge_request_diffs_sync_bytea_sha_on_update;
    SQL
  end

  subject(:migration) do
    described_class.new(
      start_id: merge_request_diffs.minimum(:id),
      end_id: merge_request_diffs.maximum(:id),
      batch_table: :merge_request_diffs,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  def create_diff(**attrs)
    merge_request_diffs.create!(
      {
        merge_request_id: merge_request.id,
        project_id: project.id
      }.merge(attrs)
    )
  end

  def hex(bytea)
    bytea&.unpack1('H*')
  end

  describe '#perform' do
    context 'when varchar columns are populated and bytea columns are NULL' do
      let!(:diff) do
        create_diff(
          base_commit_sha: base_sha,
          start_commit_sha: start_sha,
          head_commit_sha: head_sha
        )
      end

      it 'fills bytea columns by hex-decoding the varchar columns' do
        expect(diff.head_commit_sha_bytea).to be_nil

        migration.perform

        diff.reload
        expect(hex(diff.base_commit_sha_bytea)).to eq(base_sha)
        expect(hex(diff.start_commit_sha_bytea)).to eq(start_sha)
        expect(hex(diff.head_commit_sha_bytea)).to eq(head_sha)
      end
    end

    context 'when bytea columns are already populated' do
      let(:existing_bytea) { [head_sha].pack('H*') }
      let!(:diff) do
        create_diff(
          base_commit_sha: base_sha,
          start_commit_sha: start_sha,
          head_commit_sha: head_sha,
          base_commit_sha_bytea: [base_sha].pack('H*'),
          start_commit_sha_bytea: [start_sha].pack('H*'),
          head_commit_sha_bytea: existing_bytea
        )
      end

      it 'does not change already-populated bytea values' do
        expect { migration.perform }.not_to(change { diff.reload.head_commit_sha_bytea })
      end
    end

    context 'when all SHA columns are NULL' do
      let!(:diff) { create_diff }

      it 'leaves bytea columns as NULL' do
        migration.perform

        diff.reload
        expect(diff.head_commit_sha_bytea).to be_nil
        expect(diff.base_commit_sha_bytea).to be_nil
        expect(diff.start_commit_sha_bytea).to be_nil
      end
    end

    context 'when only one varchar column is populated' do
      let!(:diff) { create_diff(head_commit_sha: head_sha) }

      it 'fills only the bytea column with a non-NULL counterpart' do
        migration.perform

        diff.reload
        expect(hex(diff.head_commit_sha_bytea)).to eq(head_sha)
        expect(diff.base_commit_sha_bytea).to be_nil
        expect(diff.start_commit_sha_bytea).to be_nil
      end
    end
  end
end
