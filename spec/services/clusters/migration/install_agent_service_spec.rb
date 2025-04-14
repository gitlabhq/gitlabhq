# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Migration::InstallAgentService, feature_category: :deployment_management do
  let_it_be_with_reload(:migration) { create(:cluster_agent_migration) }
  let_it_be(:agent_token) { create(:cluster_agent_token, agent: migration.agent) }
  let_it_be(:agent) { migration.agent }

  let(:kubeclient) { instance_double(Gitlab::Kubernetes::KubeClient) }
  let(:cluster_status) { :connected }

  describe '#execute' do
    let(:namespace) { "gitlab-agent-#{agent.name}" }
    let(:kas_version) { Gitlab::Kas.install_version_info }
    let(:kas_address) { Gitlab::Kas.external_url }
    let(:helm_install_image) do
      'registry.gitlab.com/gitlab-org/cluster-integration/helm-install-image:helm-3.17.2-kube-1.32.3-alpine-3.21.3'
    end

    let(:install_command) do
      <<~CMD
        helm repo add gitlab https://charts.gitlab.io
        helm repo update
        helm upgrade --install #{agent.name} gitlab/gitlab-agent \
        --namespace #{namespace} \
        --create-namespace \
        --set image.tag\\=v#{kas_version} \
        --set config.token\\=#{agent_token.token} \
        --set config.kasAddress\\=#{kas_address}
      CMD
    end

    let(:service_account_resource) do
      Kubeclient::Resource.new(metadata: { name: 'install-gitlab-agent', namespace: 'default' })
    end

    let(:cluster_role_binding_resource) do
      Kubeclient::Resource.new(
        metadata: { name: 'install-gitlab-agent' },
        roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
        subjects: [{ kind: 'ServiceAccount', name: 'install-gitlab-agent', namespace: 'default' }]
      )
    end

    let(:install_pod_resource) do
      Kubeclient::Resource.new(
        metadata: {
          name: 'install-gitlab-agent',
          namespace: 'default'
        },
        spec: {
          containers: [{
            name: 'helm',
            image: helm_install_image,
            env: [{ name: 'INSTALL_COMMAND', value: install_command.strip }],
            command: %w[/bin/sh],
            args: %w[-c $(INSTALL_COMMAND)]
          }],
          serviceAccountName: 'install-gitlab-agent',
          restartPolicy: 'Never'
        }
      )
    end

    subject(:service) { described_class.new(migration) }

    before do
      allow(migration.cluster).to receive_messages(kubeclient: kubeclient, connection_status: cluster_status)
    end

    it 'installs the agent and associated resources into the cluster' do
      expect(kubeclient).to receive(:create_or_update_service_account)
        .with(service_account_resource)
      expect(kubeclient).to receive(:create_or_update_cluster_role_binding)
        .with(cluster_role_binding_resource)
      expect(kubeclient).to receive(:create_pod)
        .with(install_pod_resource)

      expect { service.execute }.to change { migration.agent_install_status }.from('pending').to('success')
    end

    context 'when running on GitLab.com' do
      let(:install_command) do
        <<~CMD
          helm repo add gitlab https://charts.gitlab.io
          helm repo update
          helm upgrade --install #{agent.name} gitlab/gitlab-agent \
          --namespace #{namespace} \
          --create-namespace \
          --set config.token\\=#{agent_token.token} \
          --set config.kasAddress\\=#{kas_address}
        CMD
      end

      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not specify an agent version' do
        expect(kubeclient).to receive(:create_or_update_service_account)
          .with(service_account_resource)

        expect(kubeclient).to receive(:create_or_update_cluster_role_binding)
          .with(cluster_role_binding_resource)

        expect(kubeclient).to receive(:create_pod)
          .with(install_pod_resource)

        expect { service.execute }.to change { migration.agent_install_status }.from('pending').to('success')
      end
    end

    context 'when an error is raised while creating resources' do
      before do
        allow(kubeclient).to receive(:create_or_update_service_account)
          .and_raise(Kubeclient::HttpError.new(409, 'Conflict', nil))
      end

      it 'sets the migration status to error' do
        service.execute

        expect(migration.agent_install_status).to eq('error')
        expect(migration.agent_install_message).to eq('Kubeclient::HttpError')
      end
    end

    context 'when the cluster is not connected' do
      let(:cluster_status) { :unreachable }

      it 'does not provision any resources' do
        expect(kubeclient).not_to receive(:create_namespace)

        expect { service.execute }.not_to change { migration.agent_install_status }
      end
    end

    context 'when the migration is already in progress' do
      before do
        migration.update!(agent_install_status: :in_progress)
      end

      it 'does not provision any resources' do
        expect(kubeclient).not_to receive(:create_namespace)

        expect { service.execute }.not_to change { migration.agent_install_status }
      end
    end

    context 'when the migration has already completed' do
      before do
        migration.update!(agent_install_status: :success)
      end

      it 'does not provision any resources' do
        expect(kubeclient).not_to receive(:create_namespace)

        expect { service.execute }.not_to change { migration.agent_install_status }
      end
    end
  end
end
