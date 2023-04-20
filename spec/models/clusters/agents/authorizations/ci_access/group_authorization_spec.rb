# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::GroupAuthorization, feature_category: :deployment_management do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:group).class_name('::Group').required }

  it { expect(described_class).to validate_jsonb_schema(['config']) }

  describe '#config_project' do
    let(:record) { create(:agent_ci_access_group_authorization) }

    it { expect(record.config_project).to eq(record.agent.project) }
  end
end
