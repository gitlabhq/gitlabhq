# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::OrganizationAuthorization, feature_category: :deployment_management do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:organization).class_name('Organizations::Organization').required }

  describe '#config_project' do
    let(:record) { create(:agent_ci_access_organization_authorization) }

    it { expect(record.config_project).to eq(record.agent.project) }
  end
end
