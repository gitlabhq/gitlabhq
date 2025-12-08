# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOccurrenceIdToMergeRequestLinks, feature_category: :vulnerability_management do
  let(:merge_request) do
    table(:merge_requests).create!(
      target_branch: 'main',
      source_branch: 'my-feature',
      target_project_id: project.id
    )
  end

  it_behaves_like 'backfills occurrence id from vulnerabilities' do
    let(:batch_table) { :vulnerability_merge_request_links }
    let!(:record) do
      model.create!(
        created_at: now,
        updated_at: now,
        vulnerability_id: vulnerability.id,
        merge_request_id: merge_request.id,
        project_id: project.id
      )
    end
  end
end
