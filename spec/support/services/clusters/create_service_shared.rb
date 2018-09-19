shared_context 'valid cluster create params' do
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
      }
    }
  end
end

shared_context 'invalid cluster create params' do
  let(:params) do
    {
      name: 'test-cluster',
      provider_type: :gcp,
      provider_gcp_attributes: {
        gcp_project_id: '!!!!!!!',
        zone: 'us-central1-a',
        num_nodes: 1,
        machine_type: 'machine_type-a'
      }
    }
  end
end

shared_examples 'create cluster service success' do
  before do
    stub_feature_flags(rbac_clusters: false)
  end

  it 'creates a cluster object and performs a worker' do
    expect(ClusterProvisionWorker).to receive(:perform_async)

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
  end
end

shared_examples 'create cluster service error' do
  it 'returns an error' do
    expect(ClusterProvisionWorker).not_to receive(:perform_async)
    expect { subject }.to change { Clusters::Cluster.count }.by(0)
    expect(subject.errors[:"provider_gcp.gcp_project_id"]).to be_present
  end
end
