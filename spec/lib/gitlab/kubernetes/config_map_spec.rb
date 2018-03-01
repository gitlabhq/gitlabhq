require 'spec_helper'

describe Gitlab::Kubernetes::ConfigMap do
  let(:kubeclient) { double('kubernetes client') }
  let(:application) { create(:clusters_applications_prometheus) }
  let(:config_map) { described_class.new(application.name, application.values) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

  let(:metadata) do
    {
      name: "values-content-configuration-#{application.name}",
      namespace: namespace,
      labels: { name: "values-content-configuration-#{application.name}" }
    }
  end

  describe '#generate' do
    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: { values: application.values }) }
    subject { config_map.generate }

    it 'should build a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end
