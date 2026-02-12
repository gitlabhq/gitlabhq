# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of work item types for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group, :private) }
  let_it_be(:developer) { create(:user, developer_of: namespace) }

  # TODO: Remove this when we enable types provider to return System defined types
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219133
  before do
    stub_feature_flags(work_item_system_defined_type: false)
  end

  it_behaves_like 'graphql work item type list request spec' do
    let(:current_user) { developer }
    let(:parent) { namespace }
  end
end
