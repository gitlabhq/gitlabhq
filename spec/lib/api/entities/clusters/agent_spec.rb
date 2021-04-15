# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Clusters::Agent do
  let_it_be(:cluster_agent) { create(:cluster_agent) }

  subject { described_class.new(cluster_agent).as_json }

  it 'includes basic fields' do
    expect(subject).to include(
      id: cluster_agent.id,
      config_project: a_hash_including(id: cluster_agent.project_id)
    )
  end
end
