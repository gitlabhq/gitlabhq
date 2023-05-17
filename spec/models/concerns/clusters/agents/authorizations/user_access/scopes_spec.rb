# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::Scopes, feature_category: :deployment_management do
  describe '.for_agent' do
    let_it_be(:agent_1) { create(:cluster_agent) }
    let_it_be(:agent_2) { create(:cluster_agent) }
    let_it_be(:authorization_1) { create(:agent_user_access_project_authorization, agent: agent_1) }
    let_it_be(:authorization_2) { create(:agent_user_access_project_authorization, agent: agent_2) }

    subject { Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization.for_agent(agent_1) }

    it { is_expected.to contain_exactly(authorization_1) }
  end

  describe '.preloaded' do
    let_it_be(:authorization) { create(:agent_user_access_project_authorization) }

    subject { Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization.preloaded }

    it 'preloads the associated entities' do
      expect(subject.first.association(:agent)).to be_loaded
      expect(subject.first.agent.association(:project)).to be_loaded
    end
  end
end
