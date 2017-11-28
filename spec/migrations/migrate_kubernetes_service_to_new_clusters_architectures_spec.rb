require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171124104327_migrate_kubernetes_service_to_new_clusters_architectures.rb')

describe MigrateKubernetesServiceToNewClustersArchitectures, :migration do
  context 'when user configured kubernetes from CI/CD > Clusters' do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    # Platforms::Kubernetes (New archtecture)
    let!(:cluster) do
      create(:cluster,
             projects: [project],
             user: user,
             provider_type: :gcp,
             platform_type: :kubernetes,
             provider_gcp: provider_gcp,
             platform_kubernetes: platform_kubernetes)
    end

    let(:provider_gcp) { create(:cluster_provider_gcp, :created) }
    let(:platform_kubernetes) { create(:cluster_platform_kubernetes, :configured) }

    # KubernetesService (Automatically synchronized when Platforms::Kubernetes created)
    let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

    context 'when user is using the cluster' do
      it 'migrates' do
        expect{ migrate! }.not_to change { Clusters::Cluster.count }
        expect(cluster).to be_active
        expect(kubernetes_service).not_to be_active
      end
    end

    context 'when user disabled cluster' do
      before do
        disable_cluster!
      end

      context 'when user configured kubernetes from Integration > Kubernetes' do
        before do
          kubernetes_service.update(
            active: true,
            api_url: 'http://new.kube.com',
            ca_pem: nil,
            token: 'z' * 40).reload
        end

        context 'when user is using the kubernetes service' do
          it 'migrates' do
            expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

            Clusters::Cluster.last.tap do |c|
              expect(c).to be_active
              expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
              expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
              expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
            end

            expect(kubernetes_service).not_to be_active
          end
        end

        context 'when user stopped using the kubernetes service' do
          before do
            kubernetes_service.update(active: false)
          end

          it 'migrates' do
            expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

            Clusters::Cluster.last.tap do |c|
              expect(c).not_to be_active
              expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
              expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
              expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
            end

            expect(kubernetes_service).not_to be_active
          end
        end
      end
    end

    context 'when user deleted cluster' do
      before do
        destory_cluster!
      end

      context 'when user configured kubernetes from Integration > Kubernetes' do
        let!(:new_kubernetes_service) do
          project.create_kubernetes_service(
            active: true,
            api_url: 'http://123.123.123.123',
            ca_pem: nil,
            token: 'a' * 40)
        end

        context 'when user is using the kubernetes service' do
          it 'migrates' do
            expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

            Clusters::Cluster.last.tap do |c|
              expect(c).to be_active
              expect(c.platform_kubernetes.api_url).to eq(new_kubernetes_service.api_url)
              expect(c.platform_kubernetes.ca_pem).to eq(new_kubernetes_service.ca_pem)
              expect(c.platform_kubernetes.token).to eq(new_kubernetes_service.token)
            end

            expect(new_kubernetes_service).not_to be_active
          end
        end

        context 'when user stopped using the kubernetes service' do
          before do
            new_kubernetes_service.update(active: false)
          end

          it 'migrates' do
            expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

            Clusters::Cluster.last.tap do |c|
              expect(c).not_to be_active
              expect(c.platform_kubernetes.api_url).to eq(new_kubernetes_service.api_url)
              expect(c.platform_kubernetes.ca_pem).to eq(new_kubernetes_service.ca_pem)
              expect(c.platform_kubernetes.token).to eq(new_kubernetes_service.token)
            end

            expect(new_kubernetes_service).not_to be_active
          end
        end
      end
    end
  end

  context 'when user configured kubernetes from Integration > Kubernetes' do
    let(:project) { create(:project) }
    let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

    context 'when user is using the kubernetes service' do
      it 'migrates' do
        expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

        Clusters::Cluster.last.tap do |c|
          expect(c).to be_active
          expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
          expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
          expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
        end

        expect(kubernetes_service).not_to be_active
      end
    end

    context 'when user stopped using the kubernetes service' do
      before do
        kubernetes_service.update(active: false)
      end

      it 'migrates' do
        expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

        Clusters::Cluster.last.tap do |c|
          expect(c).not_to be_active
          expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
          expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
          expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
        end

        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when nothing is configured' do
    it 'migrates' do
      expect{ migrate! }.not_to change { Clusters::Cluster.count }
    end
  end

  def disable_cluster!
    cluster.update!(enabled: false)
    kubernetes_service.update!(active: false)
  end

  def destory_cluster!
    cluster.destroy!
    kubernetes_service.destroy!
  end
end
