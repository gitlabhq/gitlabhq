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
        expect { migrate! }.to change { Clusters::Cluster.count }.by(sample_num)

        projects.each do |project|
          project.clusters.last.tap do |cluster|
            expect(cluster.enabled).to eq(active)
            expect(cluster.platform_kubernetes.api_url).to eq(project.kubernetes_service.api_url)
            expect(cluster.platform_kubernetes.ca_pem).to eq(project.kubernetes_service.ca_pem)
            expect(cluster.platform_kubernetes.token).to eq(project.kubernetes_service.token)
            expect(project.kubernetes_service).not_to be_active
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
    let(:sample_num) { 2 }
    let(:projects) { create_list(:project, sample_num) }

    let!(:kubernetes_service_template) do
      create(:kubernetes_service,
             project: nil,
             template: true,
             api_url: "https://sample.kubernetes.com",
             token: "token-sample",
             ca_pem: "ca_pem-sample")
    end

    let!(:kubernetes_services) do
      projects.map do |project|
        create(:kubernetes_service,
               project: project,
               api_url: kubernetes_service_template.api_url,
               token: kubernetes_service_template.token,
               ca_pem: kubernetes_service_template.ca_pem)
      end
    end

    it 'migrates the KubernetesService to Platform::Kubernetes without template' do
      expect { migrate! }.to change { Clusters::Cluster.count }.by(sample_num)

      projects.each do |project|
        project.clusters.last.tap do |cluster|
          expect(cluster.platform_kubernetes.api_url).to eq(project.kubernetes_service.api_url)
          expect(cluster.platform_kubernetes.ca_pem).to eq(project.kubernetes_service.ca_pem)
          expect(cluster.platform_kubernetes.token).to eq(project.kubernetes_service.token)
          expect(project.kubernetes_service).not_to be_active
        end
      end
    end
  end

  context 'when managed KubernetesService exists' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
    let!(:platform_kubernetes) { cluster.platform_kubernetes }

    let!(:kubernetes_service) do
      create(:kubernetes_service,
             project: project,
             active: cluster.enabled,
             api_url: platform_kubernetes.api_url,
             token: platform_kubernetes.token,
             ca_pem: platform_kubernetes.ca_cert)
    end

    it 'does not migrate the KubernetesService and disables the kubernetes_service' do # Because the corresponding Platform::Kubernetes already exists
      expect { migrate! }.not_to change { Clusters::Cluster.count }

      kubernetes_service.reload
      expect(kubernetes_service).not_to be_active
    end
  end

  context 'when production cluster has already been existed' do # i.e. There are no environment_scope conflicts
    let(:project) { create(:project) }
    let!(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: 'production/*', projects: [project]) }
    let!(:kubernetes_service) { create(:kubernetes_service, api_url: 'https://debug.kube.com', active: true, project: project) }

    it 'migrates the KubernetesService to Platform::Kubernetes' do
      expect { migrate! }.to change { Clusters::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when default cluster has already been existed' do
    let(:project) { create(:project) }
    let!(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project]) }
    let!(:kubernetes_service) { create(:kubernetes_service, api_url: 'https://debug.kube.com', active: true, project: project) }

    it 'migrates the KubernetesService to Platform::Kubernetes with dedicated environment_scope' do # Because environment_scope is duplicated
      expect { migrate! }.to change { Clusters::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('migrated/*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when default cluster and migrated cluster has already been existed' do
    let(:project) { create(:project) }
    let!(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project]) }
    let!(:migrated_cluster) { create(:cluster, :provided_by_gcp, environment_scope: 'migrated/*', projects: [project]) }
    let!(:kubernetes_service) { create(:kubernetes_service, api_url: 'https://debug.kube.com', active: true, project: project) }

    it 'migrates the KubernetesService to Platform::Kubernetes with dedicated environment_scope' do # Because environment_scope is duplicated
      expect { migrate! }.to change { Clusters::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('migrated0/*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when KubernetesService does not exist' do
    let!(:project) { create(:project) }

    it 'does not migrate the KubernetesService' do
      expect { migrate! }.not_to change { Clusters::Cluster.count }
    end
  end
end
