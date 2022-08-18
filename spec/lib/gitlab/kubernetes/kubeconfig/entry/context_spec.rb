# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::Kubeconfig::Entry::Context do
  describe '#to_h' do
    let(:name) { 'name' }
    let(:user) { 'user' }
    let(:cluster) { 'cluster' }

    subject { described_class.new(name: name, user: user, cluster: cluster).to_h }

    it { is_expected.to eq({ name: name, context: { cluster: cluster, user: user } }) }

    context 'with a namespace' do
      let(:namespace) { 'namespace' }

      subject { described_class.new(name: name, user: user, cluster: cluster, namespace: namespace).to_h }

      it { is_expected.to eq({ name: name, context: { cluster: cluster, user: user, namespace: namespace } }) }
    end
  end
end
