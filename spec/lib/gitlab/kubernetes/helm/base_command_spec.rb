# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::BaseCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:rbac) { false }

  let(:test_class) do
    Class.new do
      include Gitlab::Kubernetes::Helm::BaseCommand

      def initialize(rbac)
        @rbac = rbac
      end

      def name
        "test-class-name"
      end

      def rbac?
        @rbac
      end

      def files
        {
          some: 'value'
        }
      end
    end
  end

  let(:base_command) do
    test_class.new(rbac)
  end

  subject { base_command }

  it_behaves_like 'helm commands' do
    let(:commands) { '' }
  end

  describe '#pod_resource' do
    subject { base_command.pod_resource }

    it 'returns a kubeclient resoure with pod content for application' do
      is_expected.to be_an_instance_of ::Kubeclient::Resource
    end

    context 'when rbac is true' do
      let(:rbac) { true }

      it 'also returns a kubeclient resource' do
        is_expected.to be_an_instance_of ::Kubeclient::Resource
      end
    end
  end

  describe '#pod_name' do
    subject { base_command.pod_name }

    it { is_expected.to eq('install-test-class-name') }
  end
end
