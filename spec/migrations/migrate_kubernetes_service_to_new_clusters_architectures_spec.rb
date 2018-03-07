require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171124104327_migrate_kubernetes_service_to_new_clusters_architectures.rb')

describe MigrateKubernetesServiceToNewClustersArchitectures, :migration do
  context 'when unique KubernetesService exists' do
    shared_examples 'KubernetesService migration' do
      let(:sample_num) { 2 }

      let(:projects) do
        (1..sample_num).each_with_object([]) do |n, array|
          array << MigrateKubernetesServiceToNewClustersArchitectures::Project.create!
        end
      end

      let!(:kubernetes_services) do
        projects.map do |project|
          MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
            project: project,
            active: active,
            category: 'deployment',
            type: 'KubernetesService',
            properties: "{\"namespace\":\"prod\",\"api_url\":\"https://kubernetes#{project.id}.com\",\"ca_pem\":\"ca_pem#{project.id}\",\"token\":\"token#{project.id}\"}")
        end
      end

      it 'migrates the KubernetesService to Platform::Kubernetes' do
        expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(sample_num)

        projects.each do |project|
          project.clusters.last.tap do |cluster|
            expect(cluster.enabled).to eq(active)
            expect(cluster.platform_kubernetes.api_url).to eq(project.kubernetes_service.api_url)
            expect(cluster.platform_kubernetes.ca_cert).to eq(project.kubernetes_service.ca_pem)
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
  end

  context 'when unique KubernetesService spawned from Service Template' do
    let(:sample_num) { 2 }

    let(:projects) do
      (1..sample_num).each_with_object([]) do |n, array|
        array << MigrateKubernetesServiceToNewClustersArchitectures::Project.create!
      end
    end

    let!(:kubernetes_service_template) do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        template: true,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"namespace\":\"prod\",\"api_url\":\"https://sample.kubernetes.com\",\"ca_pem\":\"ca_pem-sample\",\"token\":\"token-sample\"}")
    end

    let!(:kubernetes_services) do
      projects.map do |project|
        MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
          project: project,
          category: 'deployment',
          type: 'KubernetesService',
          properties: "{\"namespace\":\"prod\",\"api_url\":\"#{kubernetes_service_template.api_url}\",\"ca_pem\":\"#{kubernetes_service_template.ca_pem}\",\"token\":\"#{kubernetes_service_template.token}\"}")
      end
    end

    it 'migrates the KubernetesService to Platform::Kubernetes without template' do
      expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(sample_num)

      projects.each do |project|
        project.clusters.last.tap do |cluster|
          expect(cluster.platform_kubernetes.api_url).to eq(project.kubernetes_service.api_url)
          expect(cluster.platform_kubernetes.ca_cert).to eq(project.kubernetes_service.ca_pem)
          expect(cluster.platform_kubernetes.token).to eq(project.kubernetes_service.token)
          expect(project.kubernetes_service).not_to be_active
        end
      end
    end
  end

  context 'when managed KubernetesService exists' do
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    let(:cluster) do
      MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create!(
        projects: [project],
        name: 'sample-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        platform_kubernetes_attributes: {
          api_url: 'https://sample.kubernetes.com',
          ca_cert: 'ca_pem-sample',
          token: 'token-sample'
        } )
    end

    let!(:kubernetes_service) do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: cluster.enabled,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"api_url\":\"#{cluster.platform_kubernetes.api_url}\"}")
    end

    it 'does not migrate the KubernetesService and disables the kubernetes_service' do # Because the corresponding Platform::Kubernetes already exists
      expect { migrate! }.not_to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }

      kubernetes_service.reload
      expect(kubernetes_service).not_to be_active
    end
  end

  context 'when production cluster has already been existed' do # i.e. There are no environment_scope conflicts
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    let(:cluster) do
      MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create!(
        projects: [project],
        name: 'sample-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        environment_scope: 'production/*',
        platform_kubernetes_attributes: {
          api_url: 'https://sample.kubernetes.com',
          ca_cert: 'ca_pem-sample',
          token: 'token-sample'
        } )
    end

    let!(:kubernetes_service) do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: true,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"api_url\":\"https://debug.kube.com\"}")
    end

    it 'migrates the KubernetesService to Platform::Kubernetes' do
      expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_cert).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when default cluster has already been existed' do
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    let!(:cluster) do
      MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create!(
        projects: [project],
        name: 'sample-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        environment_scope: '*',
        platform_kubernetes_attributes: {
          api_url: 'https://sample.kubernetes.com',
          ca_cert: 'ca_pem-sample',
          token: 'token-sample'
        } )
    end

    let!(:kubernetes_service) do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: true,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"api_url\":\"https://debug.kube.com\"}")
    end

    it 'migrates the KubernetesService to Platform::Kubernetes with dedicated environment_scope' do # Because environment_scope is duplicated
      expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('migrated/*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_cert).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when default cluster and migrated cluster has already been existed' do
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    let!(:cluster) do
      MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create!(
        projects: [project],
        name: 'sample-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        environment_scope: '*',
        platform_kubernetes_attributes: {
          api_url: 'https://sample.kubernetes.com',
          ca_cert: 'ca_pem-sample',
          token: 'token-sample'
        } )
    end

    let!(:migrated_cluster) do
      MigrateKubernetesServiceToNewClustersArchitectures::Cluster.create!(
        projects: [project],
        name: 'sample-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        environment_scope: 'migrated/*',
        platform_kubernetes_attributes: {
          api_url: 'https://sample.kubernetes.com',
          ca_cert: 'ca_pem-sample',
          token: 'token-sample'
        } )
    end

    let!(:kubernetes_service) do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: true,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"api_url\":\"https://debug.kube.com\"}")
    end

    it 'migrates the KubernetesService to Platform::Kubernetes with dedicated environment_scope' do # Because environment_scope is duplicated
      expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(1)

      kubernetes_service.reload
      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('migrated0/*')
        expect(cluster.platform_kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(cluster.platform_kubernetes.ca_cert).to eq(kubernetes_service.ca_pem)
        expect(cluster.platform_kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes_service).not_to be_active
      end
    end
  end

  context 'when KubernetesService has nullified parameters' do
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    before do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: false,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{}")
    end

    it 'does not migrate the KubernetesService and disables the kubernetes_service' do
      expect { migrate! }.not_to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }

      expect(project.kubernetes_service).not_to be_active
    end
  end

  # Platforms::Kubernetes validates `token` reagdless of the activeness,
  # whereas KubernetesService validates `token` if only it's activated
  # However, in this migration file, there are no validations because of the re-defined model class
  # therefore, we should safely add this raw to Platform::Kubernetes
  context 'when KubernetesService has empty token' do
    let(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    before do
      MigrateKubernetesServiceToNewClustersArchitectures::Service.create!(
        project: project,
        active: false,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"namespace\":\"prod\",\"api_url\":\"http://111.111.111.111\",\"ca_pem\":\"a\",\"token\":\"\"}")
    end

    it 'does not migrate the KubernetesService and disables the kubernetes_service' do
      expect { migrate! }.to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }.by(1)

      project.clusters.last.tap do |cluster|
        expect(cluster.environment_scope).to eq('*')
        expect(cluster.platform_kubernetes.namespace).to eq('prod')
        expect(cluster.platform_kubernetes.api_url).to eq('http://111.111.111.111')
        expect(cluster.platform_kubernetes.ca_cert).to eq('a')
        expect(cluster.platform_kubernetes.token).to be_empty
        expect(project.kubernetes_service).not_to be_active
      end
    end
  end

  context 'when KubernetesService does not exist' do
    let!(:project) { MigrateKubernetesServiceToNewClustersArchitectures::Project.create! }

    it 'does not migrate the KubernetesService' do
      expect { migrate! }.not_to change { MigrateKubernetesServiceToNewClustersArchitectures::Cluster.count }
    end
  end
end
