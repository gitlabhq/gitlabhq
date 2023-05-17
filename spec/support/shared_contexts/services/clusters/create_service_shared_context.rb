# frozen_string_literal: true

RSpec.shared_context 'with valid cluster create params' do
  let(:clusterable) { Clusters::Instance.new }
  let(:params) do
    {
      name: 'test-cluster',
      provider_type: :gcp,
      provider_gcp_attributes: {
        gcp_project_id: 'gcp-project',
        zone: 'us-central1-a',
        num_nodes: 1,
        machine_type: 'machine_type-a',
        legacy_abac: 'true'
      },
      clusterable: clusterable
    }
  end
end
