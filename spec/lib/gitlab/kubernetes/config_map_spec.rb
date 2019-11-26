# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::ConfigMap do
  let(:kubeclient) { double('kubernetes client') }
  let(:application) { create(:clusters_applications_prometheus) }
  let(:config_map) { described_class.new(application.name, application.files) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

  let(:metadata) do
    {
      name: "values-content-configuration-#{application.name}",
      namespace: namespace,
      labels: { name: "values-content-configuration-#{application.name}" }
    }
  end

  describe '#generate' do
    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: application.files) }
    subject { config_map.generate }

    it 'builds a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end

  describe '#config_map_name' do
    it 'returns the config_map name' do
      expect(config_map.config_map_name).to eq("values-content-configuration-#{application.name}")
    end
  end
end
