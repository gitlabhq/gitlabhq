# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Permission, feature_category: :permissions do
  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :create_issue }
  end

  it_behaves_like 'yaml backed permission'

  context 'for ignored files' do
    let(:metadata_permissions) do
      described_class.all.keys.map(&:to_s).any? { |element| element.include?('metadata.yml') }
    end

    it 'does not include metadata files' do
      expect(metadata_permissions).to be false
    end
  end

  describe '#conditionally_enables' do
    let(:source_file) { 'config/authz/permissions/resource/_foo.yml' }

    it 'returns nil when not declared' do
      permission = described_class.new({ name: '_foo', description: 'test' }, source_file)

      expect(permission.conditionally_enables).to be_nil
    end

    it 'wraps a single declared permission in an array of symbols' do
      permission = described_class.new(
        { name: '_foo', description: 'test', conditionally_enables: 'broad_permission' },
        source_file
      )

      expect(permission.conditionally_enables).to eq([:broad_permission])
    end

    it 'returns an array of symbols when several permissions are declared' do
      permission = described_class.new(
        {
          name: '_foo', description: 'test',
          conditionally_enables: %w[push_code create_merge_request_from create_merge_request_in]
        },
        source_file
      )

      expect(permission.conditionally_enables).to eq(
        [:push_code, :create_merge_request_from, :create_merge_request_in]
      )
    end

    it 'returns nil when declared as null' do
      permission = described_class.new(
        { name: '_foo', description: 'test', conditionally_enables: nil },
        source_file
      )

      expect(permission.conditionally_enables).to be_nil
    end
  end
end
