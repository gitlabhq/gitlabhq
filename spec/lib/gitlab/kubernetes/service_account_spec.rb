# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::ServiceAccount do
  let(:name) { 'a_service_account' }
  let(:namespace_name) { 'a_namespace' }
  let(:service_account) { described_class.new(name, namespace_name) }

  it { expect(service_account.name).to eq(name) }
  it { expect(service_account.namespace_name).to eq(namespace_name) }

  describe '#generate' do
    let(:resource) do
      ::Kubeclient::Resource.new(metadata: { name: name, namespace: namespace_name })
    end

    subject { service_account.generate }

    it 'builds a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end
