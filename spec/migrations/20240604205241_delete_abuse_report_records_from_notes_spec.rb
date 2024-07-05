# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteAbuseReportRecordsFromNotes, feature_category: :code_review_workflow do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let!(:merge_request) do
    table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'feature')
  end

  let!(:notes) { table(:notes) }
  let!(:abuse_report1) { table(:abuse_reports).create! }
  let!(:abuse_report2) { table(:abuse_reports).create! }

  describe '#up' do
    before do
      notes.create!(noteable_type: 'AbuseReport', noteable_id: abuse_report1.id)
      notes.create!(noteable_type: 'AbuseReport', noteable_id: abuse_report2.id)
      notes.create!(noteable_type: 'MergeRequest', noteable_id: merge_request.id)

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes abuse report notes' do
      migrate!

      expect(notes.count).to eq(1)
      expect(notes.first).to have_attributes(
        noteable_type: 'MergeRequest',
        noteable_id: merge_request.id
      )
    end
  end
end
