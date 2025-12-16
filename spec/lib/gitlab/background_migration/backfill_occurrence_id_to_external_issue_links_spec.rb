# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOccurrenceIdToExternalIssueLinks, feature_category: :vulnerability_management do
  it_behaves_like 'backfills occurrence id from vulnerabilities' do
    let(:batch_table) { :vulnerability_external_issue_links }
    let!(:record) do
      model.create!(
        created_at: now,
        updated_at: now,
        author_id: user.id,
        vulnerability_id: vulnerability.id,
        project_id: project.id,
        external_project_key: 'A',
        external_issue_key: '1'
      )
    end
  end
end
