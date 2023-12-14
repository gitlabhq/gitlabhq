# frozen_string_literal: true

require 'spec_helper'

require_relative '../concerns/membership_actions_shared_examples'

RSpec.describe Groups::GroupMembersController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:membershipable) { create(:group, :public) }

  let(:membershipable_path) { group_path(membershipable) }

  describe 'GET /groups/*group_id/-/group_members/request_access' do
    subject(:request) do
      get request_access_group_group_members_path(group_id: membershipable)
    end

    it_behaves_like 'request_accessable'
  end
end
