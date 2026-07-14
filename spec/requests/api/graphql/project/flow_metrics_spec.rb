# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting project flow metrics', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, :repository, group: group) }
  # This is done so we can use the same count expectations in the shared examples and
  # reuse the shared example for the group-level test.
  let_it_be(:project2) { project1 }
  let_it_be(:production_environment1) { create(:environment, :production, project: project1) }
  let_it_be(:production_environment2) { production_environment1 }
  let_it_be(:current_user) { create(:user, maintainer_of: project1) }

  let(:full_path) { project1.full_path }
  let(:context) { :project }

  it_behaves_like 'value stream analytics flow metrics issueCount examples'

  it_behaves_like 'value stream analytics flow metrics deploymentCount examples'
end
