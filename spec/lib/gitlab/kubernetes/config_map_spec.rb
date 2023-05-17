# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::ConfigMap do
  let(:kubeclient) { double('kubernetes client') }
  let(:name) { 'my-name' }
  let(:files) { [] }
  let(:config_map) { described_class.new(name, files) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

  let(:metadata) do
    {
      name: "values-content-configuration-#{name}",
      namespace: namespace,
      labels: { name: "values-content-configuration-#{name}" }
    }
  end

  describe '#generate' do
    let(:resource) do
      ::Kubeclient::Resource.new(metadata: metadata, data: files)
    end

    subject { config_map.generate }

    it 'builds a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end

  describe '#config_map_name' do
    it 'returns the config_map name' do
      expect(config_map.config_map_name)
        .to eq("values-content-configuration-#{name}")
    end
  end
end
