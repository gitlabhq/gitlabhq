# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::MergeRequestDiff, feature_category: :code_review_workflow do
  let_it_be(:user)          { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project)       { merge_request.target_project }
  let_it_be(:entity)        { described_class.new(merge_request.merge_request_diffs.first) }

  before do
    merge_request.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    merge_request.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e')
  end

  subject(:json) { entity.as_json }

  it "includes expected fields" do
    expected_fields = %i[
      id head_commit_sha base_commit_sha start_commit_sha created_at
      merge_request_id state real_size patch_id_sha
    ]

    is_expected.to include(*expected_fields)
  end

  it "returns expected data" do
    merge_request_diff = merge_request.merge_request_diffs.first

    expect(entity.as_json).to eq(
      {
        id: merge_request_diff.id,
        head_commit_sha: merge_request_diff.head_commit_sha,
        base_commit_sha: merge_request_diff.base_commit_sha,
        start_commit_sha: merge_request_diff.start_commit_sha,
        created_at: merge_request_diff.created_at,
        merge_request_id: merge_request.id,
        state: merge_request_diff.state,
        real_size: merge_request_diff.real_size,
        patch_id_sha: merge_request_diff.patch_id_sha
      }
    )
  end
end
