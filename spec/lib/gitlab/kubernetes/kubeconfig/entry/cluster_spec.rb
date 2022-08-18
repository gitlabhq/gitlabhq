# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::Kubeconfig::Entry::Cluster do
  describe '#to_h' do
    let(:name) { 'name' }
    let(:url) { 'url' }

    subject { described_class.new(name: name, url: url).to_h }

    it { is_expected.to eq({ name: name, cluster: { server: url } }) }

    context 'with a certificate' do
      let(:cert) { 'certificate' }
      let(:cert_encoded) { Base64.strict_encode64(cert) }

      subject { described_class.new(name: name, url: url, ca_pem: cert).to_h }

      it { is_expected.to eq({ name: name, cluster: { server: url, 'certificate-authority-data': cert_encoded } }) }
    end
  end
end
