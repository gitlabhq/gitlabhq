# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::ConfigMaps::AwsNodeAuth do
  describe '#generate' do
    let(:role) { 'arn:aws:iam::123456789012:role/node-instance-role' }

    let(:name) { 'aws-auth' }
    let(:namespace) { 'kube-system' }
    let(:role_config) do
      [{
        'rolearn' => role,
        'username' => 'system:node:{{EC2PrivateDNSName}}',
        'groups' => [
          'system:bootstrappers',
          'system:nodes'
        ]
      }]
    end

    subject { described_class.new(role).generate }

    it 'builds a Kubeclient Resource' do
      expect(subject).to be_a(Kubeclient::Resource)

      expect(subject.metadata.name).to eq(name)
      expect(subject.metadata.namespace).to eq(namespace)

      expect(YAML.safe_load(subject.data.mapRoles)).to eq(role_config)
    end
  end
end
