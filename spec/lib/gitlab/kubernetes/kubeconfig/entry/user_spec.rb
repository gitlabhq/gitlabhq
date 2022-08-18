# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Kubernetes::Kubeconfig::Entry::User do
  describe '#to_h' do
    let(:name) { 'name' }
    let(:token) { 'token' }

    subject { described_class.new(name: name, token: token).to_h }

    it { is_expected.to eq({ name: name, user: { token: token } }) }
  end
end
