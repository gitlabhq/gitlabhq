require 'spec_helper'

describe Gitlab::Kubernetes::Helm do
  let(:client) { double('kubernetes client') }
  let(:helm) { described_class.new(client) }
  let(:namespace) { Gitlab::Kubernetes::Namespace.new(described_class::NAMESPACE, client) }
  let(:install_helm) { true }
  let(:chart) { 'stable/a_chart' }
  let(:application_name) { 'app_name' }
  let(:command) { Gitlab::Kubernetes::Helm::InstallCommand.new(application_name, install_helm, chart) }
  subject { helm }

  before do
    allow(Gitlab::Kubernetes::Namespace).to receive(:new).with(described_class::NAMESPACE, client).and_return(namespace)
  end

  describe '#initialize' do
    it 'creates a namespace object' do
      expect(Gitlab::Kubernetes::Namespace).to receive(:new).with(described_class::NAMESPACE, client)

      subject
    end
  end

  describe '#install' do
    before do
      allow(client).to receive(:create_pod).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before creating the POD' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.install(command)
    end
  end

  describe '#installation_status' do
    let(:phase) { Gitlab::Kubernetes::Pod::RUNNING }
    let(:pod) { Kubeclient::Resource.new(status: { phase: phase }) } # partial representation

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod).with(command.pod_name, described_class::NAMESPACE).once.and_return(pod)

      expect(subject.installation_status(command.pod_name)).to eq(phase)
    end
  end

  describe '#installation_log' do
    let(:log) { 'some output' }
    let(:response) { RestClient::Response.new(log) }

    it 'fetches POD phase from kubernetes cluster' do
      expect(client).to receive(:get_pod_log).with(command.pod_name, described_class::NAMESPACE).once.and_return(response)

      expect(subject.installation_log(command.pod_name)).to eq(log)
    end
  end

  describe '#delete_installation_pod!' do
    it 'deletes the POD from kubernetes cluster' do
      expect(client).to receive(:delete_pod).with(command.pod_name, described_class::NAMESPACE).once

      subject.delete_installation_pod!(command.pod_name)
    end
  end

  describe '#helm_init_command' do
    subject { helm.send(:helm_init_command, command) }

    context 'when command.install_helm is true' do
      let(:install_helm) { true }

      it { is_expected.to eq('helm init >/dev/null') }
    end

    context 'when command.install_helm is false' do
      let(:install_helm) { false }

      it { is_expected.to eq('helm init --client-only >/dev/null') }
    end
  end

  describe '#helm_install_command' do
    subject { helm.send(:helm_install_command, command) }

    context 'when command.chart is nil' do
      let(:chart) { nil }

      it { is_expected.to be_nil }
    end

    context 'when command.chart is set' do
      let(:chart) { 'stable/a_chart' }

      it { is_expected.to eq("helm install #{chart} --name #{application_name} --namespace #{namespace.name} >/dev/null")}
    end
  end
end
