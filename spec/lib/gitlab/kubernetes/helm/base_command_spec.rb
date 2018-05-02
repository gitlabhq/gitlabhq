require 'spec_helper'

describe Gitlab::Kubernetes::Helm::BaseCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:base_command) { described_class.new(application.name) }

  subject { base_command }

  it_behaves_like 'helm commands' do
    let(:commands) { '' }
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
