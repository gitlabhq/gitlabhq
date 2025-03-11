# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateClosedMergedMrs, feature_category: :code_review_workflow do
  describe '#perform' do
    let(:user) { table(:users).create!(name: 'user1', email: 'user1@example.com', projects_limit: 5) }
    let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
    let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }

    let(:project) do
      table(:projects).create!(
        name: "project",
        path: "project",
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        organization_id: organization.id
      )
    end

    let(:opened) { MergeRequest.available_states[:opened] }
    let(:merged) { MergeRequest.available_states[:merged] }
    let(:closed) { MergeRequest.available_states[:closed] }

    let(:mr_table) { table(:merge_requests) }
    let(:metrics_table) { table(:merge_request_metrics) }

    let(:mr_defaults) do
      { target_project_id: project.id, target_branch: "main", updated_at: DateTime.parse("2024-12-20") }
    end

    let(:metric_defaults) { { target_project_id: project.id, merged_by_id: user.id, merged_at: DateTime.yesterday } }

    let!(:merge_request_1) { mr_table.create!({ source_branch: "m1", state_id: closed, **mr_defaults }) } # bad
    let!(:merge_request_2) { mr_table.create!({ source_branch: "m2", state_id: merged, **mr_defaults }) } # good
    let!(:merge_request_3) { mr_table.create!({ source_branch: "m3", state_id: closed, **mr_defaults }) } # bad
    let!(:merge_request_4) { mr_table.create!({ source_branch: "m4", state_id: merged, **mr_defaults }) } # good
    let!(:merge_request_5) { mr_table.create!({ source_branch: "m5", state_id: merged, **mr_defaults }) } # good
    let!(:merge_request_6) { mr_table.create!({ source_branch: "m6", state_id: opened, **mr_defaults }) } # do not touch

    let!(:merge_request_metrics_1) do
      metrics_table.create!({ merge_request_id: merge_request_1.id, **metric_defaults })
    end

    let!(:merge_request_metrics_2) do
      metrics_table.create!({ merge_request_id: merge_request_2.id, **metric_defaults })
    end

    let!(:merge_request_metrics_3) do
      metrics_table.create!({ merge_request_id: merge_request_3.id, **metric_defaults })
    end

    let!(:merge_request_metrics_4) do
      metrics_table.create!({ merge_request_id: merge_request_4.id, **metric_defaults })
    end

    let!(:merge_request_metrics_5) do
      metrics_table.create!({ merge_request_id: merge_request_5.id, **metric_defaults })
    end

    let!(:merge_request_metrics_6) do
      metrics_table.create!({ merge_request_id: merge_request_6.id, **metric_defaults })
    end

    subject(:migration) do
      described_class.new(
        start_id: merge_request_1.id,
        end_id: merge_request_6.id,
        batch_table: :merge_requests,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it "changes 'closed' merge requests back to 'merged'" do
      migration

      expect(merge_request_1.reload.state_id).to be(merged)
      expect(merge_request_2.reload.state_id).to be(merged)
      expect(merge_request_3.reload.state_id).to be(merged)
      expect(merge_request_4.reload.state_id).to be(merged)
      expect(merge_request_5.reload.state_id).to be(merged)
      expect(merge_request_6.reload.state_id).to be(opened)
    end
  end
end
