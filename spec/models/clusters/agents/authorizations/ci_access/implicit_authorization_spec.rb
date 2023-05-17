# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }

  subject { described_class.new(agent: agent) }

  it { expect(subject.agent).to eq(agent) }
  it { expect(subject.agent_id).to eq(agent.id) }
  it { expect(subject.config_project).to eq(agent.project) }
  it { expect(subject.config).to eq({}) }
end
