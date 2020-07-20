# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190606163724_migrate_legacy_managed_clusters_to_unmanaged.rb')

RSpec.describe MigrateLegacyManagedClustersToUnmanaged do
  let(:cluster_type) { 'project_type' }
  let(:created_at) { 1.hour.ago }

  let!(:cluster) do
    table(:clusters).create!(
      name: 'cluster',
      cluster_type: described_class::Cluster.cluster_types[cluster_type],
      managed: true,
      created_at: created_at
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

  context 'cluster has a kubernetes namespace associated' do
    before do
      table(:clusters_kubernetes_namespaces).create!(
        cluster_id: cluster.id,
        namespace: 'namespace'
      )
    end

    it 'does not update the cluster' do
      migrate!
      expect(cluster.reload).to be_managed
    end
  end

  context 'cluster was recently created' do
    let(:created_at) { 2.minutes.ago }

    it 'does not update the cluster' do
      migrate!
      expect(cluster.reload).to be_managed
    end
  end
end
