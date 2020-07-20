# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::GenericSecret do
  let(:secret) { described_class.new(name, data, namespace) }
  let(:name) { 'example-name' }
  let(:data) { 'example-data' }
  let(:namespace) { 'example-namespace' }

  describe '#generate' do
    subject { secret.generate }

    let(:resource) do
      ::Kubeclient::Resource.new(
        type: 'Opaque',
        metadata: { name: name, namespace: namespace },
        data: data
      )
    end

    it { is_expected.to eq(resource) }
  end
end
