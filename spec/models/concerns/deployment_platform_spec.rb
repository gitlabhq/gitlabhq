require 'rails_helper'

describe DeploymentPlatform do
  let(:project) { create(:project) }

  describe '#deployment_platform' do
    subject { project.deployment_platform }

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service and a Kubernetes template configured' do
      let!(:kubernetes_service) { create(:kubernetes_service, template: true) }

      it 'returns a platform kubernetes' do
        expect(subject).to be_a_kind_of(Clusters::Platforms::Kubernetes)
      end

      it 'creates a cluster and a platform kubernetes' do
        expect { subject }
          .to change { Clusters::Cluster.count }.by(1)
          .and change { Clusters::Platforms::Kubernetes.count }.by(1)
      end

      it 'includes appropriate attributes for Cluster' do
        cluster = subject.cluster
        expect(cluster.name).to eq('kubernetes-template')
        expect(cluster.project).to eq(project)
        expect(cluster.provider_type).to eq('user')
        expect(cluster.platform_type).to eq('kubernetes')
      end

      it 'creates a platform kubernetes' do
        expect { subject }.to change { Clusters::Platforms::Kubernetes.count }.by(1)
      end

      it 'copies attributes from Clusters::Platform::Kubernetes template into the new Cluster::Platforms::Kubernetes' do
        expect(subject.api_url).to eq(kubernetes_service.api_url)
        expect(subject.ca_pem).to eq(kubernetes_service.ca_pem)
        expect(subject.token).to eq(kubernetes_service.token)
        expect(subject.namespace).to eq(kubernetes_service.namespace)
      end
    end

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service and no Kubernetes template configured' do
      it { is_expected.to be_nil }
    end

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it 'returns the Kubernetes platform' do
        expect(subject).to eq(platform_kubernetes)
      end
    end

    context 'when user configured kubernetes integration from project services' do
      let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

      it 'returns the Kubernetes service' do
        expect(subject).to eq(kubernetes_service)
      end
    end

    context 'when the cluster creation fails' do
      let!(:kubernetes_service) { create(:kubernetes_service, template: true) }

      before do
        allow_any_instance_of(Clusters::Cluster).to receive(:persisted?).and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end
end
