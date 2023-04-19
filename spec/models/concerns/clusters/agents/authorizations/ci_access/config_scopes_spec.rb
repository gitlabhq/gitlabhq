# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::ConfigScopes, feature_category: :deployment_management do
  describe '.with_available_ci_access_fields' do
    let(:project) { create(:project) }

    let!(:agent_authorization_0)     { create(:agent_ci_access_project_authorization, project: project) }
    let!(:agent_authorization_1)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: {} }) }
    let!(:agent_authorization_2)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { agent: {} } }) }
    let!(:impersonate_authorization) { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { impersonate: {} } }) }
    let!(:ci_user_authorization)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { ci_user: {} } }) }
    let!(:ci_job_authorization)      { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { ci_job: {} } }) }
    let!(:unexpected_authorization)  { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { unexpected: {} } }) }

    subject { Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization.with_available_ci_access_fields(project) }

    it { is_expected.to contain_exactly(agent_authorization_0, agent_authorization_1, agent_authorization_2) }
  end
end
