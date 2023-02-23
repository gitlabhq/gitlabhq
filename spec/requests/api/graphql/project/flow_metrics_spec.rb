# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project flow metrics', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  # This is done so we can use the same count expectations in the shared examples and
  # reuse the shared example for the group-level test.
  let_it_be(:project2) { project1 }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project1]) }

  it_behaves_like 'value stream analytics flow metrics issueCount examples' do
    let(:full_path) { project1.full_path }
    let(:context) { :project }
  end
end
