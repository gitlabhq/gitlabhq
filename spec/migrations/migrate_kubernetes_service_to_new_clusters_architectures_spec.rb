require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171124104327_migrate_kubernetes_service_to_new_clusters_architectures.rb')

describe MigrateKubernetesServiceToNewClustersArchitectures, :migration do
  context 'when unique KubernetesService exists' do
    shared_examples 'KubernetesService migration' do
      let(:sample_num) { 2 }
      let(:projects) { create_list(:project, sample_num) }

      let!(:kubernetes_services) do
        projects.map do |project|
          create(:kubernetes_service,
                 project: project,
                 active: active,
                 api_url: "https://kubernetes#{project.id}.com",
                 token: defined?(token) ? token : "token#{project.id}",
                 ca_pem: "ca_pem#{project.id}")
        end
      end

      it 'migrates the KubernetesService to Platform::Kubernetes' do
        expect{ migrate! }.to change { Clusters::Cluster.count }.by(sample_num)

        projects.each do |project|
          project.clusters.last.tap do |cluster|
            expect(cluster.enabled).to eq(active)
            expect(cluster.platform_kubernetes.api_url).to eq(project.kubernetes_service.api_url)
            expect(cluster.platform_kubernetes.ca_pem).to eq(project.kubernetes_service.ca_pem)
            expect(cluster.platform_kubernetes.token).to eq(project.kubernetes_service.token)
            expect(project.kubernetes_service).not_to be_active
            expect(project.kubernetes_service.properties['migrated']).to be_truthy
          end
        end
      end
    end

    context 'when KubernetesService is active' do
      let(:active) { true }

      it_behaves_like 'KubernetesService migration'
    end

    context 'when KubernetesService is not active' do
      let(:active) { false }

      # Platforms::Kubernetes validates `token` reagdless of the activeness
      # KubernetesService validates `token` if only it's activated
      # However, in this migration file, there are no validations because of the migration specific model class
      # therefore, Validation Error will not happen in this case and just migrate data
      let(:token) { '' }

      it_behaves_like 'KubernetesService migration'
    end
  end

  context 'when unique KubernetesService spawned from Service Template' do
    it 'migrates the KubernetesService to Platform::Kubernetes' do

    end
  end

  context 'when synced KubernetesService exists' do
    it 'does not migrate the KubernetesService' do # Because the corresponding Platform::Kubernetes already exists

    end
  end

  context 'when KubernetesService does not exist' do
    it 'does not migrate the KubernetesService' do

    end
  end

  # context 'when user configured kubernetes from CI/CD > Clusters' do
  #   let(:project) { create(:project) }
  #   let(:user) { create(:user) }

  #   # Platforms::Kubernetes (New archtecture)
  #   let!(:cluster) do
  #     create(:cluster,
  #            projects: [project],
  #            user: user,
  #            provider_type: :gcp,
  #            platform_type: :kubernetes,
  #            provider_gcp: provider_gcp,
  #            platform_kubernetes: platform_kubernetes)
  #   end

  #   let(:provider_gcp) { create(:cluster_provider_gcp, :created) }
  #   let(:platform_kubernetes) { create(:cluster_platform_kubernetes, :configured) }

  #   # KubernetesService (Automatically synchronized when Platforms::Kubernetes created)
  #   let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

  #   context 'when user is using the cluster' do
  #     it 'migrates' do
  #       expect{ migrate! }.not_to change { Clusters::Cluster.count }
  #       expect(cluster).to be_active
  #       expect(kubernetes_service).not_to be_active
  #     end
  #   end

  #   context 'when user disabled cluster' do
  #     before do
  #       disable_cluster!
  #     end

  #     context 'when user configured kubernetes from Integration > Kubernetes' do
  #       before do
  #         kubernetes_service.update(
  #           active: true,
  #           api_url: 'http://new.kube.com',
  #           ca_pem: nil,
  #           token: 'z' * 40).reload
  #       end

  #       context 'when user is using the kubernetes service' do
  #         it 'migrates' do
  #           expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #           Clusters::Cluster.last.tap do |c|
  #             expect(c).to be_active
  #             expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
  #             expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
  #             expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
  #           end

  #           expect(kubernetes_service).not_to be_active
  #         end
  #       end

  #       context 'when user stopped using the kubernetes service' do
  #         before do
  #           kubernetes_service.update(active: false)
  #         end

  #         it 'migrates' do
  #           expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #           Clusters::Cluster.last.tap do |c|
  #             expect(c).not_to be_active
  #             expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
  #             expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
  #             expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
  #           end

  #           expect(kubernetes_service).not_to be_active
  #         end
  #       end
  #     end
  #   end

  #   context 'when user deleted cluster' do
  #     before do
  #       destory_cluster!
  #     end

  #     context 'when user configured kubernetes from Integration > Kubernetes' do
  #       let!(:new_kubernetes_service) do
  #         project.create_kubernetes_service(
  #           active: true,
  #           api_url: 'http://123.123.123.123',
  #           ca_pem: nil,
  #           token: 'a' * 40)
  #       end

  #       context 'when user is using the kubernetes service' do
  #         it 'migrates' do
  #           expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #           Clusters::Cluster.last.tap do |c|
  #             expect(c).to be_active
  #             expect(c.platform_kubernetes.api_url).to eq(new_kubernetes_service.api_url)
  #             expect(c.platform_kubernetes.ca_pem).to eq(new_kubernetes_service.ca_pem)
  #             expect(c.platform_kubernetes.token).to eq(new_kubernetes_service.token)
  #           end

  #           expect(new_kubernetes_service).not_to be_active
  #         end
  #       end

  #       context 'when user stopped using the kubernetes service' do
  #         before do
  #           new_kubernetes_service.update(active: false)
  #         end

  #         it 'migrates' do
  #           expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #           Clusters::Cluster.last.tap do |c|
  #             expect(c).not_to be_active
  #             expect(c.platform_kubernetes.api_url).to eq(new_kubernetes_service.api_url)
  #             expect(c.platform_kubernetes.ca_pem).to eq(new_kubernetes_service.ca_pem)
  #             expect(c.platform_kubernetes.token).to eq(new_kubernetes_service.token)
  #           end

  #           expect(new_kubernetes_service).not_to be_active
  #         end
  #       end
  #     end
  #   end
  # end

  # context 'when user configured kubernetes from Integration > Kubernetes' do
  #   let(:project) { create(:project) }
  #   let!(:kubernetes_service) { create(:kubernetes_service, project: project) }

  #   context 'when user is using the kubernetes service' do
  #     it 'migrates' do
  #       expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #       Clusters::Cluster.last.tap do |c|
  #         expect(c).to be_active
  #         expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
  #         expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
  #         expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
  #       end

  #       expect(kubernetes_service).not_to be_active
  #     end
  #   end

  #   context 'when user stopped using the kubernetes service' do
  #     before do
  #       kubernetes_service.update(active: false)
  #     end

  #     it 'migrates' do
  #       expect{ migrate! }.to change { Clusters::Cluster.count }.by(1)

  #       Clusters::Cluster.last.tap do |c|
  #         expect(c).not_to be_active
  #         expect(c.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
  #         expect(c.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
  #         expect(c.platform_kubernetes.token).to eq(kubernetes_service.token)
  #       end

  #       expect(kubernetes_service).not_to be_active
  #     end
  #   end
  # end

  # context 'when nothing is configured' do
  #   it 'migrates' do
  #     expect{ migrate! }.not_to change { Clusters::Cluster.count }
  #   end
  # end

  # def disable_cluster!
  #   cluster.update!(enabled: false)
  #   kubernetes_service.update!(active: false)
  # end

  # def destory_cluster!
  #   cluster.destroy!
  #   kubernetes_service.destroy!
  # end
end
