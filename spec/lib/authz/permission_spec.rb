# spec/lib/authz/permission_spec.rb
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  let(:scopes) { ['project'] }
  let(:source_file) { 'config/authz/permissions/permission/test.yml' }
  let(:definition) do
    {
      name: 'test_permission',
      description: 'Test permission description',
      scopes: scopes,
      feature_category: 'team_planning'
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

  describe '#scopes' do
    specify do
      expect(permission.scopes).to eq(scopes)
    end

    context 'when scopes are not defined' do
      let(:scopes) { nil }

      it 'returns an empty array' do
        expect(permission.scopes).to eq([])
      end
    end
  end

  describe '#source_file' do
    specify do
      expect(permission.source_file).to eq(source_file)
    end
  end
end
