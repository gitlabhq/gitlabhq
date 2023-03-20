# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::DeployTokens::DestroyService, feature_category: :deployment_management do
  it_behaves_like 'a deploy token deletion service' do
    let_it_be(:entity) { create(:group) }
    let_it_be(:deploy_token_class) { GroupDeployToken }
    let_it_be(:deploy_token) { create(:deploy_token, :group, groups: [entity]) }
  end
end
