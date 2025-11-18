# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestFileDiffsPartitionedTable, feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_request_diff_files) { table(:merge_request_diff_files) }
  let(:merge_request_diff_files_99208b8fac) { table(:merge_request_diff_files_99208b8fac) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }

  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:merge_request_1) do
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: 'feature',
      source_project_id: project.id
    )
  end

  let!(:merge_request_diff) do
    merge_request_diffs.create!(
      merge_request_id: merge_request_1.id,
      project_id: project.id
    )
  end

  let!(:merge_request_diff_file) do
    merge_request_diff_files.create!(
      merge_request_diff_id: merge_request_diff.id,
      relative_order: 0,
      new_file: true,
      renamed_file: false,
      deleted_file: true,
      too_large: false,
      a_mode: 100500,
      b_mode: 100755,
      new_path: 'new_path',
      old_path: 'old_path',
      encoded_file_path: false,
      project_id: project.id
    )
  end

  let(:job_params) do
    {
      start_cursor: [0, 0],
      end_cursor: [10, 10],
      batch_table: :merge_request_diff_files,
      batch_column: :merge_request_diff_id,
      pause_ms: 0,
      sub_batch_size: EnqueueBackfillMergeRequestDiffFilesPartitionedTable::SUB_BATCH_SIZE,
      job_arguments: %w[merge_request_diff_files_99208b8fac],
      connection: connection
    }
  end

  let(:columns) do
    <<-TEXT
      merge_request_diff_id,
      relative_order,
      new_file,
      renamed_file,
      deleted_file,
      too_large,
      a_mode,
      b_mode,
      new_path,
      old_path,
      encoded_file_path,
      project_id
    TEXT
  end

  context "when upserting new records" do
    before do
      # create a record in merge_requests_diff_files manually, avoiding the triggers
      #   that would automatically copy it over to merge_request_diff_files_99208b8fac
      #
      connection.transaction do
        connection.execute <<~SQL
          ALTER TABLE merge_request_diff_files DISABLE TRIGGER ALL; -- Don't sync records to partitioned table

          INSERT INTO merge_request_diff_files(
            #{columns}
          ) VALUES (
            #{merge_request_diff.id},
            1,
            true,
            false,
            true,
            false,
            100500,
            100755,
            'new_path',
            'old_path',
            false,
            #{project.id}
          );

          INSERT INTO merge_request_diff_files(
            #{columns}
          ) VALUES (
            #{merge_request_diff.id},
            2,
            true,
            false,
            true,
            false,
            100500,
            100755,
            'new_path',
            'old_path',
            false,
            NULL
          );

          ALTER TABLE merge_request_diff_files ENABLE TRIGGER ALL;
        SQL
      end
    end

    let(:mrdf_all) { merge_request_diff_files.all }
    let(:mrdf_99208b8fac_all) { merge_request_diff_files_99208b8fac.all }

    it "does not create a duplicate record in merge_request_diff_files_99208b8fac" do
      expect(mrdf_all.count).to eq(3)
      expect(mrdf_99208b8fac_all.count).to eq(1)
    end

    it "backfills the 'missing' record" do
      expect(mrdf_99208b8fac_all.count).to eq(1)

      background_migration = described_class.new(**job_params)
      background_migration.perform

      expect(mrdf_99208b8fac_all.count).to eq(3)

      mrdf_all.count.times do |i|
        expect(
          mrdf_all[i].attributes.except("project_id") == mrdf_99208b8fac_all[i].attributes.except("project_id")
        ).to be(true)

        expect(mrdf_99208b8fac_all[i][:project_id]).to eq(project.id)
      end
    end
  end
end
