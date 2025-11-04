# spec/lib/authz/permission_spec.rb
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  let(:scopes) { ['project'] }
  let(:source_file) { 'config/authz/permissions/permission/test.yml' }
  let(:name) { 'test_permission' }
  let(:action) { nil }
  let(:resource) { nil }
  let(:available_for_tokens) { true }
  let(:definition) do
    {
      name: name,
      description: 'Test permission description',
      feature_category: 'team_planning',
      action: action,
      resource: resource,
      available_for_tokens: available_for_tokens
    }
  end

  subject(:permission) { described_class.new(definition, source_file) }

  describe '.all' do
    it 'loads all permission definitions' do
      expect(described_class.all).to be_a(Hash)
      expect(described_class.all).not_to be_empty
    end
  end

  describe '.get' do
    it 'returns the permission by name' do
      permission = described_class.get(:create_issue)

      expect(permission).to be_a(described_class)
      expect(permission.name).to eq('create_issue')
    end

    it 'returns nil for non-existent permission' do
      expect(described_class.get(:non_existent_permission)).to be_nil
    end
  end

  describe '.all_for_tokens' do
    subject(:all_for_tokens) { described_class.all_for_tokens }

    it 'loads all permission definitions available for tokens' do
      expect(all_for_tokens).to be_a(Array)
      expect(all_for_tokens).not_to be_empty
      expect(all_for_tokens.first.available_for_tokens?).to be(true)
    end
  end

  describe '.defined?' do
    subject(:defined) { described_class.defined?(permission) }

    context 'when the permission exists' do
      context 'when the permission is passed as a symbol' do
        let(:permission) { :create_issue }

        it { is_expected.to be(true) }
      end

      context 'when the permission is passed as a string' do
        let(:permission) { 'create_issue' }

        it { is_expected.to be(true) }
      end
    end

    context 'when the permission does not exist' do
      let(:permission) { :non_existent_permission }

      it { is_expected.to be(false) }
    end
  end

  describe '#name' do
    specify do
      expect(permission.name).to eq('test_permission')
    end
  end

  describe '#description' do
    specify do
      expect(permission.description).to eq('Test permission description')
    end
  end

  describe '#feature_category' do
    specify do
      expect(permission.feature_category).to eq('team_planning')
    end
  end

  describe '#source_file' do
    specify do
      expect(permission.source_file).to eq(source_file)
    end
  end

  describe '#action' do
    let(:name) { 'another_test_permission' }

    subject { permission.action }

    it { is_expected.to eq('another') }

    context 'when an action is defined' do
      let(:action) { 'another_test' }

      it 'is expected to use the defined action' do
        is_expected.to eq('another_test')
      end
    end

    context 'when a resource is defined' do
      let(:resource) { 'permission' }

      it 'is expected to infer the action based on the resource' do
        is_expected.to eq('another_test')
      end
    end

    context 'when an action and resource are defined' do
      let(:action) { 'another_test' }
      let(:resource) { 'test_permission' }

      it 'is expected use the defined action' do
        is_expected.to eq('another_test')
      end
    end
  end

  describe '#resource' do
    let(:name) { 'another_test_permission' }

    subject { permission.resource }

    it { is_expected.to eq('test_permission') }

    context 'when a resource is defined' do
      let(:resource) { 'permission' }

      it 'is expected to use the defined resource' do
        is_expected.to eq('permission')
      end
    end

    context 'when an action is defined' do
      let(:action) { 'another_test' }

      it 'is expected to infer the resource based on the action' do
        is_expected.to eq('permission')
      end
    end

    context 'when a resource and action are defined' do
      let(:action) { 'another_test' }
      let(:resource) { 'test_permission' }

      it 'is expected use the defined resource' do
        is_expected.to eq('test_permission')
      end
    end
  end

  describe '#available_for_tokens?' do
    subject { permission.available_for_tokens? }

    it { is_expected.to be(true) }

    context 'when available_for_tokens is not defined' do
      let(:available_for_tokens) { nil }

      it { is_expected.to be(false) }
    end
  end
end
