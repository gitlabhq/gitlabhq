# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::MergeRequestApprovals do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request, current_user: user).as_json }

  before do
    merge_request.project.add_developer(user)
  end

  it 'serializes an approved merge request' do
    create(:approval, merge_request: merge_request, user: user)

    is_expected.to eq({
      user_has_approved: true,
      user_can_approve: false,
      approved: true,
      approved_by: [{
        user: API::Entities::UserBasic.new(user).as_json
      }]
    })
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
