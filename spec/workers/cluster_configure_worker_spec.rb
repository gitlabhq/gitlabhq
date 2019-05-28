# frozen_string_literal: true

require 'spec_helper'

describe ClusterConfigureWorker, '#perform' do
  let(:worker) { described_class.new }

  shared_examples 'configured cluster' do
    it 'creates a namespace' do
      expect(Clusters::RefreshService).to receive(:create_or_update_namespaces_for_cluster).with(cluster).once

      worker.perform(cluster.id)
    end
  end

  shared_examples 'unconfigured cluster' do
    it 'does not create a namespace' do
      expect(Clusters::RefreshService).not_to receive(:create_or_update_namespaces_for_cluster)

      worker.perform(cluster.id)
    end
  end

  context 'group cluster' do
    let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
    let(:group) { cluster.group }

    context 'when group has a project' do
      let!(:project) { create(:project, group: group) }

      it_behaves_like 'unconfigured cluster'
    end

    context 'when group has project in a sub-group' do
      let!(:subgroup) { create(:group, parent: group) }
      let!(:project) { create(:project, group: subgroup) }

      it_behaves_like 'unconfigured cluster'
    end
  end

  context 'when provider type is gcp' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }

    it_behaves_like 'configured cluster'
  end

  context 'when provider type is user' do
    let!(:cluster) { create(:cluster, :project, :provided_by_user) }

    it_behaves_like 'configured cluster'
  end

  context 'when cluster is not managed' do
    let(:cluster) { create(:cluster, :not_managed) }

    it 'does not configure the cluster' do
      expect(Clusters::RefreshService).not_to receive(:create_or_update_namespaces_for_cluster)

      described_class.new.perform(cluster.id)
    end
  end

  context 'when cluster does not exist' do
    it 'does not provision a cluster' do
      expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:execute)

      described_class.new.perform(123)
    end
  end
end
