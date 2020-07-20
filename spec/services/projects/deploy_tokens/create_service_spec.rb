# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployTokens::CreateService do
  it_behaves_like 'a deploy token creation service' do
    let(:entity) { create(:project) }
    let(:deploy_token_class) { ProjectDeployToken }
  end
end
