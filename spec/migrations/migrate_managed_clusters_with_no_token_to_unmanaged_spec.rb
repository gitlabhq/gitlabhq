# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateManagedClustersWithNoTokenToUnmanaged do
  let(:cluster_type) { 'project_type' }
  let(:created_at) { Date.new(2018, 11, 1).midnight }

  let!(:cluster) do
    table(:clusters).create!(
      name: 'cluster',
      cluster_type: described_class::Cluster.cluster_types[cluster_type],
      managed: true,
      created_at: created_at
    )
  end

  let!(:kubernetes_namespace) do
    table(:clusters_kubernetes_namespaces).create!(
      cluster_id: cluster.id,
      namespace: 'namespace'
    )
  end

  it 'marks the cluster as unmanaged' do
    migrate!
    expect(cluster.reload).not_to be_managed
  end

  context 'cluster is not project type' do
    let(:cluster_type) { 'group_type' }

    it 'does not update the cluster' do
      migrate!
      expect(cluster.reload).to be_managed
    end
  end

  context 'kubernetes namespace has a service account token' do
    before do
      kubernetes_namespace.update!(encrypted_service_account_token: "TOKEN")
    end

    it 'does not update the cluster' do
      migrate!
      expect(cluster.reload).to be_managed
    end
  end

  context 'cluster was created after the cutoff' do
    let(:created_at) { Date.new(2019, 1, 1).midnight }

    it 'does not update the cluster' do
      migrate!
      expect(cluster.reload).to be_managed
    end
  end
end
