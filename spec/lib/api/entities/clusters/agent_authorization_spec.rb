# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Clusters::AgentAuthorization do
  let_it_be(:authorization) { create(:agent_group_authorization) }

  subject { described_class.new(authorization).as_json }

  it 'includes basic fields' do
    expect(subject).to include(
      id: authorization.agent_id,
      config_project: a_hash_including(id: authorization.agent.project_id),
      configuration: authorization.config
    )
  end
end
