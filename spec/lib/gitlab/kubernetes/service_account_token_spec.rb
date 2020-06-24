# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::ServiceAccountToken do
  let(:name) { 'token-name' }
  let(:service_account_name) { 'a_service_account' }
  let(:namespace_name) { 'a_namespace' }
  let(:service_account_token) { described_class.new(name, service_account_name, namespace_name) }

  it { expect(service_account_token.name).to eq(name) }
  it { expect(service_account_token.service_account_name).to eq(service_account_name) }
  it { expect(service_account_token.namespace_name).to eq(namespace_name) }

  describe '#generate' do
    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: {
          name: name,
          namespace: namespace_name,
          annotations: {
            'kubernetes.io/service-account.name': service_account_name
          }
        },
        type: 'kubernetes.io/service-account-token'
      )
    end

    subject { service_account_token.generate }

    it 'builds a Kubeclient Resource' do
      is_expected.to eq(resource)
    end
  end
end
