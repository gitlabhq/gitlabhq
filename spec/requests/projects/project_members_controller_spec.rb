# frozen_string_literal: true

require 'spec_helper'

require_relative '../concerns/membership_actions_shared_examples'

RSpec.describe Projects::ProjectMembersController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:membershipable) { create(:project, :public, namespace: create(:group, :public)) }

  let(:membershipable_path) { project_path(membershipable) }

  describe 'GET /*namespace_id/:project_id/-/project_members/request_access' do
    subject(:request) do
      get request_access_namespace_project_project_members_path(
        namespace_id: membershipable.namespace,
        project_id: membershipable
      )
    end

    it_behaves_like 'request_accessable'
  end
end
