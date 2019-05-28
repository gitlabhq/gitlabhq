# frozen_string_literal: true

require 'spec_helper'

describe Clusters::RefreshService do
  shared_examples 'creates a kubernetes namespace' do
    let(:token) { 'aaaaaa' }
    let(:service_account_creator) { double(Clusters::Gcp::Kubernetes::CreateOrUpdateServiceAccountService, execute: true) }
    let(:secrets_fetcher) { double(Clusters::Gcp::Kubernetes::FetchKubernetesTokenService, execute: token) }

    it 'creates a kubernetes namespace' do
      expect(Clusters::Gcp::Kubernetes::CreateOrUpdateServiceAccountService).to receive(:namespace_creator).and_return(service_account_creator)
      expect(Clusters::Gcp::Kubernetes::FetchKubernetesTokenService).to receive(:new).and_return(secrets_fetcher)

      expect { subject }.to change(project.kubernetes_namespaces, :count)

      kubernetes_namespace = cluster.kubernetes_namespaces.first
      expect(kubernetes_namespace).to be_present
      expect(kubernetes_namespace.project).to eq(project)
    end
  end

  shared_examples 'does not create a kubernetes namespace' do
    it 'does not create a new kubernetes namespace' do
      expect(Clusters::Gcp::Kubernetes::CreateOrUpdateServiceAccountService).not_to receive(:namespace_creator)
      expect(Clusters::Gcp::Kubernetes::FetchKubernetesTokenService).not_to receive(:new)

      expect { subject }.not_to change(Clusters::KubernetesNamespace, :count)
    end
  end

  describe '.create_or_update_namespaces_for_cluster' do
    let(:cluster) { create(:cluster, :provided_by_user, :project) }
    let(:project) { cluster.project }

    subject { described_class.create_or_update_namespaces_for_cluster(cluster) }

    context 'cluster is project level' do
      include_examples 'creates a kubernetes namespace'

      context 'when project already has kubernetes namespace' do
        before do
          create(:cluster_kubernetes_namespace, project: project, cluster: cluster)
        end

        include_examples 'does not create a kubernetes namespace'
      end
    end

    context 'cluster is group level' do
      let(:cluster) { create(:cluster, :provided_by_user, :group) }
      let(:group) { cluster.group }
      let(:project) { create(:project, group: group) }

      include_examples 'creates a kubernetes namespace'

      context 'when project already has kubernetes namespace' do
        before do
          create(:cluster_kubernetes_namespace, project: project, cluster: cluster)
        end

        include_examples 'does not create a kubernetes namespace'
      end
    end
  end

  describe '.create_or_update_namespaces_for_project' do
    let(:project) { create(:project) }

    subject { described_class.create_or_update_namespaces_for_project(project) }

    it 'creates no kubernetes namespaces' do
      expect { subject }.not_to change(project.kubernetes_namespaces, :count)
    end

    context 'project has a project cluster' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, cluster_type: :project_type, projects: [project]) }

      include_examples 'creates a kubernetes namespace'

      context 'when project already has kubernetes namespace' do
        before do
          create(:cluster_kubernetes_namespace, project: project, cluster: cluster)
        end

        include_examples 'does not create a kubernetes namespace'
      end
    end

    context 'project belongs to a group cluster' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      let(:group) { cluster.group }
      let(:project) { create(:project, group: group) }

      include_examples 'does not create a kubernetes namespace'

      context 'when project already has kubernetes namespace' do
        before do
          create(:cluster_kubernetes_namespace, project: project, cluster: cluster)
        end

        include_examples 'does not create a kubernetes namespace'
      end
    end

    context 'cluster is not managed' do
      let!(:cluster) { create(:cluster, :project, :not_managed, projects: [project]) }

      include_examples 'does not create a kubernetes namespace'
    end
  end
end
