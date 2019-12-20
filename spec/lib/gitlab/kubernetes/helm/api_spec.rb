# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Api do
  let(:client) { double('kubernetes client') }
  let(:helm) { described_class.new(client) }
  let(:gitlab_namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:namespace) { Gitlab::Kubernetes::Namespace.new(gitlab_namespace, client) }
  let(:application_name) { 'app-name' }
  let(:rbac) { false }
  let(:files) { {} }

  let(:command) do
    Gitlab::Kubernetes::Helm::InstallCommand.new(
      name: application_name,
      chart: 'chart-name',
      rbac: rbac,
      files: files
    )
  end

  subject { helm }

  before do
    allow(Gitlab::Kubernetes::Namespace).to receive(:new).with(gitlab_namespace, client).and_return(namespace)
    allow(client).to receive(:create_config_map)
  end

  describe '#initialize' do
    it 'creates a namespace object' do
      expect(Gitlab::Kubernetes::Namespace).to receive(:new).with(gitlab_namespace, client)

      subject
    end
  end

  describe '#uninstall' do
    before do
      allow(client).to receive(:create_pod).and_return(nil)
      allow(client).to receive(:get_config_map).and_return(nil)
      allow(client).to receive(:create_config_map).and_return(nil)
      allow(client).to receive(:delete_pod).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before creating the POD' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.uninstall(command)
    end

    it 'removes an existing pod before installing' do
      expect(client).to receive(:delete_pod).with('install-app-name', 'gitlab-managed-apps').once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.uninstall(command)
    end

    context 'with a ConfigMap' do
      let(:resource) { Gitlab::Kubernetes::ConfigMap.new(application_name, files).generate }

      it 'creates a ConfigMap on kubeclient' do
        expect(client).to receive(:create_config_map).with(resource).once

        subject.install(command)
      end

      context 'config map already exists' do
        before do
          expect(client).to receive(:get_config_map).with("values-content-configuration-#{application_name}", gitlab_namespace).and_return(resource)
        end

        it 'updates the config map' do
          expect(client).to receive(:update_config_map).with(resource).once

          subject.install(command)
        end
      end
    end
  end

  describe '#install' do
    before do
      allow(client).to receive(:create_pod).and_return(nil)
      allow(client).to receive(:get_config_map).and_return(nil)
      allow(client).to receive(:create_config_map).and_return(nil)
      allow(client).to receive(:create_service_account).and_return(nil)
      allow(client).to receive(:create_cluster_role_binding).and_return(nil)
      allow(client).to receive(:delete_pod).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before creating the POD' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.install(command)
    end

    it 'removes an existing pod before installing' do
      expect(client).to receive(:delete_pod).with('install-app-name', 'gitlab-managed-apps').once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.install(command)
    end

    context 'with a ConfigMap' do
      let(:resource) { Gitlab::Kubernetes::ConfigMap.new(application_name, files).generate }

      it 'creates a ConfigMap on kubeclient' do
        expect(client).to receive(:create_config_map).with(resource).once

        subject.install(command)
      end

      context 'config map already exists' do
        before do
          expect(client).to receive(:get_config_map).with("values-content-configuration-#{application_name}", gitlab_namespace).and_return(resource)
        end

        it 'updates the config map' do
          expect(client).to receive(:update_config_map).with(resource).once

          subject.install(command)
        end
      end
    end

    context 'without a service account' do
      it 'does not create a service account on kubeclient' do
        expect(client).not_to receive(:create_service_account)
        expect(client).not_to receive(:create_cluster_role_binding)

        subject.install(command)
      end
    end

    context 'with a service account' do
      let(:command) { Gitlab::Kubernetes::Helm::InitCommand.new(name: application_name, files: files, rbac: rbac) }

      context 'rbac-enabled cluster' do
        let(:rbac) { true }

        let(:service_account_resource) do
          Kubeclient::Resource.new(metadata: { name: 'tiller', namespace: 'gitlab-managed-apps' })
        end

        let(:cluster_role_binding_resource) do
          Kubeclient::Resource.new(
            metadata: { name: 'tiller-admin' },
            roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
            subjects: [{ kind: 'ServiceAccount', name: 'tiller', namespace: 'gitlab-managed-apps' }]
          )
        end

        context 'service account and cluster role binding does not exist' do
          before do
            expect(client).to receive(:get_service_account).with('tiller', 'gitlab-managed-apps').and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil))
            expect(client).to receive(:get_cluster_role_binding).with('tiller-admin').and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil))
          end

          it 'creates a service account, followed the cluster role binding on kubeclient' do
            expect(client).to receive(:create_service_account).with(service_account_resource).once.ordered
            expect(client).to receive(:create_cluster_role_binding).with(cluster_role_binding_resource).once.ordered

            subject.install(command)
          end
        end

        context 'service account already exists' do
          before do
            expect(client).to receive(:get_service_account).with('tiller', 'gitlab-managed-apps').and_return(service_account_resource)
            expect(client).to receive(:get_cluster_role_binding).with('tiller-admin').and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil))
          end

          it 'updates the service account, followed by creating the cluster role binding' do
            expect(client).to receive(:update_service_account).with(service_account_resource).once.ordered
            expect(client).to receive(:create_cluster_role_binding).with(cluster_role_binding_resource).once.ordered

            subject.install(command)
          end
        end

        context 'service account and cluster role binding already exists' do
          before do
            expect(client).to receive(:get_service_account).with('tiller', 'gitlab-managed-apps').and_return(service_account_resource)
            expect(client).to receive(:get_cluster_role_binding).with('tiller-admin').and_return(cluster_role_binding_resource)
          end

          it 'updates the service account, followed by creating the cluster role binding' do
            expect(client).to receive(:update_service_account).with(service_account_resource).once.ordered
            expect(client).to receive(:update_cluster_role_binding).with(cluster_role_binding_resource).once.ordered

            subject.install(command)
          end
        end

        context 'a non-404 error is thrown' do
          before do
            expect(client).to receive(:get_service_account).with('tiller', 'gitlab-managed-apps').and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
          end

          it 'raises an error' do
            expect { subject.install(command) }.to raise_error(Kubeclient::HttpError)
          end
        end
      end

      context 'legacy abac cluster' do
        it 'does not create a service account on kubeclient' do
          expect(client).not_to receive(:create_service_account)
          expect(client).not_to receive(:create_cluster_role_binding)

          subject.install(command)
        end
      end
    end
  end

  describe '#status' do
    let(:phase) { Gitlab::Kubernetes::Pod::RUNNING }
    let(:pod) { Kubeclient::Resource.new(status: { phase: phase }) } # partial representation

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod).with(command.pod_name, gitlab_namespace).once.and_return(pod)

      expect(subject.status(command.pod_name)).to eq(phase)
    end
  end

  describe '#log' do
    let(:log) { 'some output' }
    let(:response) { RestClient::Response.new(log) }

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod_log).with(command.pod_name, gitlab_namespace).once.and_return(response)

      expect(subject.log(command.pod_name)).to eq(log)
    end
  end

  describe '#delete_pod!' do
    it 'deletes the POD from kubernetes cluster' do
      expect(client).to receive(:delete_pod).with('install-app-name', 'gitlab-managed-apps').once

      subject.delete_pod!('install-app-name')
    end

    context 'when the resource being deleted does not exist' do
      it 'catches the error' do
        expect(client).to receive(:delete_pod).with('install-app-name', 'gitlab-managed-apps')
          .and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil))

        subject.delete_pod!('install-app-name')
      end
    end
  end

  describe '#get_config_map' do
    before do
      allow(namespace).to receive(:ensure_exists!).once
      allow(client).to receive(:get_config_map).and_return(nil)
    end

    it 'ensures the namespace exists before retrieving the config map' do
      expect(namespace).to receive(:ensure_exists!).once

      subject.get_config_map('example-config-map-name')
    end

    it 'gets the config map on kubeclient' do
      expect(client).to receive(:get_config_map)
        .with('example-config-map-name', namespace.name)
        .once

      subject.get_config_map('example-config-map-name')
    end
  end
end
