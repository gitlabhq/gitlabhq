# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Role do
  let(:role) { described_class.new(name: name, namespace: namespace, rules: rules) }
  let(:name) { 'example-name' }
  let(:namespace) { 'example-namespace' }

  let(:rules) do
    [{
      apiGroups: %w[hello.world],
      resources: %w[oil diamonds coffee],
      verbs: %w[say do walk run]
    }]
  end

  describe '#generate' do
    subject { role.generate }

    let(:resource) do
      ::Kubeclient::Resource.new(
        metadata: { name: name, namespace: namespace },
        rules: rules
      )
    end

    it { is_expected.to eq(resource) }
  end
end
