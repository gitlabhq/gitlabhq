require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Api do
  let(:client) { double('kubernetes client') }
  let(:helm) { described_class.new(client) }
  let(:gitlab_namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:namespace) { Gitlab::Kubernetes::Namespace.new(gitlab_namespace, client) }
  let(:application) { create(:clusters_applications_prometheus) }

  let(:command) do
    Gitlab::Kubernetes::Helm::InstallCommand.new(
      application.name,
      chart: application.chart,
      values: application.values
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
      let(:resource) { Gitlab::Kubernetes::ConfigMap.new(application.name, application.values).generate }

      it 'creates a ConfigMap on kubeclient' do
        expect(client).to receive(:create_config_map).with(resource).once

        subject.install(command)
      end
    end
  end

  describe '#installation_status' do
    let(:phase) { Gitlab::Kubernetes::Pod::RUNNING }
    let(:pod) { Kubeclient::Resource.new(status: { phase: phase }) } # partial representation

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod).with(command.pod_name, gitlab_namespace).once.and_return(pod)

      expect(subject.installation_status(command.pod_name)).to eq(phase)
    end
  end

  describe '#installation_log' do
    let(:log) { 'some output' }
    let(:response) { RestClient::Response.new(log) }

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod_log).with(command.pod_name, gitlab_namespace).once.and_return(response)

      expect(subject.installation_log(command.pod_name)).to eq(log)
    end
  end

  describe '#delete_installation_pod!' do
    it 'deletes the POD from kubernetes cluster' do
      expect(client).to receive(:delete_pod).with(command.pod_name, gitlab_namespace).once

      subject.delete_installation_pod!(command.pod_name)
    end
  end
end
