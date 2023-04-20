# frozen_string_literal: true

RSpec.shared_examples 'create cluster service success' do
  it 'creates a cluster object' do
    expect { subject }
      .to change { Clusters::Cluster.count }.by(1)
      .and change { Clusters::Providers::Gcp.count }.by(1)

    expect(subject.name).to eq('test-cluster')
    expect(subject.user).to eq(user)
    expect(subject.project).to eq(project)
    expect(subject.provider.gcp_project_id).to eq('gcp-project')
    expect(subject.provider.zone).to eq('us-central1-a')
    expect(subject.provider.num_nodes).to eq(1)
    expect(subject.provider.machine_type).to eq('machine_type-a')
    expect(subject.provider.access_token).to eq(access_token)
    expect(subject.provider).to be_legacy_abac
    expect(subject.platform).to be_nil
    expect(subject.namespace_per_environment).to eq true
  end
end

RSpec.shared_examples 'create cluster service error' do
  it 'returns an error' do
    expect { subject }.to change { Clusters::Cluster.count }.by(0)
    expect(subject.errors[:"provider_gcp.gcp_project_id"]).to be_present
  end
end
