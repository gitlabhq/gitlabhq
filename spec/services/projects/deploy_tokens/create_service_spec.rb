# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::CreateService, feature_category: :continuous_delivery do
  it_behaves_like 'a deploy token creation service' do
    let(:entity) { create(:project) }
    let(:deploy_token_class) { ProjectDeployToken }
  end
end
