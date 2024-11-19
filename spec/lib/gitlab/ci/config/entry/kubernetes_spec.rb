# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Kubernetes, feature_category: :kubernetes_management do
  let(:config) { Hash(namespace: 'namespace') }

  subject { described_class.new(config) }

  describe 'attributes' do
    it { is_expected.to respond_to(:namespace) }
    it { is_expected.to respond_to(:has_namespace?) }
  end

  describe 'validations' do
    describe 'config' do
      context 'is a hash containing known keys' do
        let(:config) { Hash(namespace: 'namespace') }

        it { is_expected.to be_valid }
      end

      context 'is a hash containing an unknown key' do
        let(:config) { Hash(unknown: 'attribute') }

        it { is_expected.not_to be_valid }
      end

      context 'is a string' do
        let(:config) { 'config' }

        it { is_expected.not_to be_valid }
      end

      context 'is empty' do
        let(:config) { {} }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'namespace' do
      let(:config) { Hash(namespace: namespace) }

      context 'is a string' do
        let(:namespace) { 'namespace' }

        it { is_expected.to be_valid }
      end

      context 'is a hash' do
        let(:namespace) { Hash(key: 'namespace') }

        it { is_expected.not_to be_valid }
      end
    end

    describe 'agent' do
      let(:config) { Hash(agent: agent) }

      context 'is a string' do
        let(:agent) { 'path/to/project:example-agent' }

        it { is_expected.to be_valid }
      end

      context 'is a hash' do
        let(:agent) { { key: 'agent' } }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
