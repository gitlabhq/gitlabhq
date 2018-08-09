require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Api do
  let(:client) { double('kubernetes client') }
  let(:helm) { described_class.new(client) }
  let(:gitlab_namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:namespace) { Gitlab::Kubernetes::Namespace.new(gitlab_namespace, client) }
  let(:application) { create(:clusters_applications_prometheus) }

  let(:command) { application.install_command }

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

  describe '#install' do
    before do
      allow(client).to receive(:create_pod).and_return(nil)
      allow(client).to receive(:create_config_map).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before creating the POD' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.install(command)
    end

    context 'with a ConfigMap' do
      let(:resource) { Gitlab::Kubernetes::ConfigMap.new(application.name, application.files).generate }

      it 'creates a ConfigMap on kubeclient' do
        expect(client).to receive(:create_config_map).with(resource).once

        subject.install(command)
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
      expect(client).to receive(:delete_pod).with(command.pod_name, gitlab_namespace).once

      subject.delete_pod!(command.pod_name)
    end
  end

  describe '#delete_config_map' do
    it 'deletes the ConfigMap from the kubernetes cluster' do
      config_map_name = 'values-content-configuration-helm'
      expect(client).to receive(:delete_config_map).with(config_map_name, gitlab_namespace).once

      subject.delete_config_map(config_map_name)
    end
  end
end
