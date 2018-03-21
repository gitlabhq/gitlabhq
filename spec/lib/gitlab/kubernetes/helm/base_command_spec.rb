require 'spec_helper'

describe Gitlab::Kubernetes::Helm::BaseCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:base_command) { described_class.new(application.name) }

  describe '#generate_script' do
    let(:helm_version) { Gitlab::Kubernetes::Helm::HELM_VERSION }
    let(:command) do
      <<~HEREDOC
         set -eo pipefail
         apk add -U ca-certificates openssl >/dev/null
         wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v#{helm_version}-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
         mv /tmp/linux-amd64/helm /usr/bin/
      HEREDOC
    end

    subject { base_command.generate_script }

    it 'should return a command that prepares the environment for helm-cli' do
      expect(subject).to eq(command)
    end
  end

  describe '#pod_resource' do
    subject { base_command.pod_resource }

    it 'should returns a kubeclient resoure with pod content for application' do
      is_expected.to be_an_instance_of ::Kubeclient::Resource
    end
  end

  describe '#config_map?' do
    subject { base_command.config_map? }

    it { is_expected.to be_falsy }
  end

  describe '#pod_name' do
    subject { base_command.pod_name }

    it { is_expected.to eq('install-helm') }
  end
end
