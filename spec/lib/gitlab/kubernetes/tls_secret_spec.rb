# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::TlsSecret do
  let(:secret) { described_class.new(name, cert, key, namespace) }
  let(:name) { 'example-name' }
  let(:cert) { 'example-cert' }
  let(:key) { 'example-key' }
  let(:namespace) { 'example-namespace' }

  let(:data) do
    {
      'tls.crt': Base64.strict_encode64(cert),
      'tls.key': Base64.strict_encode64(key)
    }
  end

  describe '#generate' do
    subject { secret.generate }

    let(:resource) do
      ::Kubeclient::Resource.new(
        type: 'kubernetes.io/tls',
        metadata: { name: name, namespace: namespace },
        data: data
      )
    end

    it { is_expected.to eq(resource) }
  end
end
