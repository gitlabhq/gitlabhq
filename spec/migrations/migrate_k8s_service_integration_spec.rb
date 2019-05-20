# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190517153211_migrate_k8s_service_integration.rb')

describe MigrateK8sServiceIntegration, :migration do
  context 'template service' do
    context 'with namespace' do
      let!(:service) do
        MigrateK8sServiceIntegration::Service.create!(
          active: true,
          template: true,
          category: 'deployment',
          type: 'KubernetesService',
          properties: "{\"namespace\":\"prod\",\"api_url\":\"https://sample.kubernetes.com\",\"ca_pem\":\"ca_pem-sample\",\"token\":\"token-sample\"}"
        )
      end

      let(:cluster) { MigrateK8sServiceIntegration::Cluster.instance_type.last! }
      let(:platform) { cluster.platform_kubernetes }

      it 'migrates the KubernetesService template to Platform::Kubernetes' do
        expect { migrate! }.to change { MigrateK8sServiceIntegration::Cluster.count }.by(1)

        expect(cluster).to be_enabled
        expect(cluster).to be_user
        expect(cluster).not_to be_managed
        expect(cluster.environment_scope).to eq('*')
        expect(platform.api_url).to eq('https://sample.kubernetes.com')
        expect(platform.ca_cert).to eq('ca_pem-sample')
        expect(platform.namespace).to eq('prod')
        expect(platform.token).to eq('token-sample')
      end
    end

    context 'without namespace' do
      let!(:service) do
        MigrateK8sServiceIntegration::Service.create!(
          active: true,
          template: true,
          category: 'deployment',
          type: 'KubernetesService',
          properties: "{\"namespace\":\"\",\"api_url\":\"https://sample.kubernetes.com\",\"ca_pem\":\"ca_pem-sample\",\"token\":\"token-sample\"}"
        )
      end

      let(:cluster) { MigrateK8sServiceIntegration::Cluster.instance_type.last! }
      let(:platform) { cluster.platform_kubernetes }

      it 'migrates the KubernetesService template to Platform::Kubernetes' do
        expect { migrate! }.to change { MigrateK8sServiceIntegration::Cluster.count }.by(1)

        expect(cluster).to be_enabled
        expect(cluster).to be_user
        expect(cluster).not_to be_managed
        expect(cluster.environment_scope).to eq('*')
        expect(platform.api_url).to eq('https://sample.kubernetes.com')
        expect(platform.ca_cert).to eq('ca_pem-sample')
        expect(platform.namespace).to be_nil
        expect(platform.token).to eq('token-sample')
      end
    end

    context 'with nullified parameters' do
      let!(:service) do
        MigrateK8sServiceIntegration::Service.create!(
          active: true,
          template: true,
          category: 'deployment',
          type: 'KubernetesService',
          properties: "{}"
        )
      end

      it 'does not migrate the KubernetesService' do
        expect { migrate! }.not_to change { MigrateK8sServiceIntegration::Cluster.count }
      end
    end

    context 'when disabled' do
      let!(:service) do
        MigrateK8sServiceIntegration::Service.create!(
          active: false,
          template: true,
          category: 'deployment',
          type: 'KubernetesService',
          properties: "{\"namespace\":\"prod\",\"api_url\":\"https://sample.kubernetes.com\",\"ca_pem\":\"ca_pem-sample\",\"token\":\"token-sample\"}"
        )
      end

      let(:cluster) { MigrateK8sServiceIntegration::Cluster.instance_type.last! }
      let(:platform) { cluster.platform_kubernetes }

      it 'migrates the KubernetesService template to Platform::Kubernetes' do
        expect { migrate! }.to change { MigrateK8sServiceIntegration::Cluster.count }.by(1)

        expect(cluster).not_to be_enabled
        expect(cluster).to be_user
        expect(cluster).not_to be_managed
        expect(cluster.environment_scope).to eq('*')
        expect(platform.api_url).to eq('https://sample.kubernetes.com')
        expect(platform.ca_cert).to eq('ca_pem-sample')
        expect(platform.namespace).to eq('prod')
        expect(platform.token).to eq('token-sample')
      end
    end
  end

  context 'non-template service' do
    let!(:service) do
      MigrateK8sServiceIntegration::Service.create!(
        active: true,
        template: false,
        category: 'deployment',
        type: 'KubernetesService',
        properties: "{\"namespace\":\"prod\",\"api_url\":\"https://sample.kubernetes.com\",\"ca_pem\":\"ca_pem-sample\",\"token\":\"token-sample\"}"
      )
    end

    it 'does not migrate the KubernetesService' do
      expect { migrate! }.not_to change { MigrateK8sServiceIntegration::Cluster.count }
    end
  end
end
