# frozen_string_literal: true

require 'spec_helper'

# In EE this entity presents the merge request's approval state instead, as
# ee/spec/lib/ee/api/entities/merge_request_approvals_spec.rb describes.
# Since the CE test also runs in EE, we need to skip it there.
RSpec.describe API::Entities::MergeRequestApprovals, feature_category: :source_code_management, unless: Gitlab.ee? do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { create(:user, developer_of: project) }
  let(:expected_attributes) { %i[user_has_approved user_can_approve approved approved_by] }

  subject(:entity) { described_class.new(merge_request, current_user: user).as_json }

  context 'when the MR has been approved' do
    let(:approval) { create(:approval, merge_request: merge_request, user: user) }

    before do
      approval
    end

    it 'serializes an approved merge request' do
      expect(entity.keys).to match_array(expected_attributes)
      expect(entity[:user_has_approved]).to be(true)
      expect(entity[:user_can_approve]).to be(false)
      expect(entity[:approved]).to be(true)
      expect(entity[:approved_by].count).to eq(1)
      approved_by = entity[:approved_by].first
      expect(approved_by[:user]).to eq(API::Entities::UserBasic.new(user).as_json)
      # Some systems have different precision so we need to use be_within(1.second) to prevent flakiness
      expect(approved_by[:approved_at]).to be_within(1.second).of(approval.created_at)
    end
  end

  it 'serializes a merge request that is not approved' do
    is_expected.to eq({
      user_has_approved: false,
      user_can_approve: true,
      approved: false,
      approved_by: []
    })
  end
end
