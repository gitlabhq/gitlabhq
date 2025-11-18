# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroup, feature_category: :permissions do
  let(:definition) do
    {
      name: 'test_group',
      description: 'Test group description',
      # include read_project twice to ensure uniqueness is handled
      permissions: %w[read_project write_project read_project],
      available_for_tokens: true
    }
  end

  it_behaves_like 'loadable yaml permission or permission group' do
    let(:definition_name) { :update_wiki }
    let(:definition) { super() }
  end

  describe 'instance methods' do
    let(:permission_group) { described_class.new(definition, 'definition.yml') }

    describe '#permissions' do
      it 'returns sorted unique permissions as symbols' do
        expect(permission_group.permissions).to eq([:read_project, :write_project])
      end
    end
  end
end
