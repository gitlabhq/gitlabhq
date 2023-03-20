# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::DestroyService, feature_category: :continuous_delivery do
  it_behaves_like 'a deploy token deletion service' do
    let_it_be(:entity) { create(:project) }
    let_it_be(:deploy_token_class) { ProjectDeployToken }
    let_it_be(:deploy_token) { create(:deploy_token, projects: [entity]) }
  end
end
