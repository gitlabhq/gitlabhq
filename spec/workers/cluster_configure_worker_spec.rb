# frozen_string_literal: true

require 'spec_helper'

describe ClusterConfigureWorker, '#perform' do
  let(:worker) { described_class.new }

  context 'when group cluster' do
    let(:cluster) { create(:cluster, :group, :provided_by_gcp) }
    let(:group) { cluster.group }

    context 'when group has no projects' do
      it 'does not create a namespace' do
        expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).not_to receive(:execute)

        worker.perform(cluster.id)
      end
    end

    context 'when group has a project' do
      let!(:project) { create(:project, group: group) }

      it 'creates a namespace for the project' do
        expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).to receive(:execute).once

        worker.perform(cluster.id)
      end
    end

    context 'when group has project in a sub-group' do
      let!(:subgroup) { create(:group, parent: group) }
      let!(:project) { create(:project, group: subgroup) }

      it 'creates a namespace for the project' do
        expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).to receive(:execute).once

        worker.perform(cluster.id)
      end
    end
  end

  context 'when provider type is gcp' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

    it 'configures kubernetes platform' do
      expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).to receive(:execute)

      described_class.new.perform(cluster.id)
    end
  end

  context 'when provider type is user' do
    let(:cluster) { create(:cluster, :project, :provided_by_user) }

    it 'configures kubernetes platform' do
      expect_any_instance_of(Clusters::Gcp::Kubernetes::CreateOrUpdateNamespaceService).to receive(:execute)

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
