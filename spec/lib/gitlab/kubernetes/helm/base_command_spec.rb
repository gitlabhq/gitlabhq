require 'spec_helper'

class TestClass
  include Gitlab::Kubernetes::Helm::BaseCommand
  def name
    "test-class-name"
  end

  def files
    {
      some: 'value'
    }
  end
end

describe Gitlab::Kubernetes::Helm::BaseCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:base_command) { TestClass.new }
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

  describe '#pod_name' do
    subject { base_command.pod_name }

    it { is_expected.to eq('install-test-class-name') }
  end
end
