# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroups::Assignable, feature_category: :permissions do
  let(:definition) do
    {
      name: 'action_resource',
      description: 'Grants action on resource',
      feature_category: 'feature_category_name',
      # include read_project twice to ensure uniqueness is handled
      permissions: %w[read_resource write_resource read_resource]
    }
  end

  let(:file_path) { 'path/to/resource/action.yml' }
  let(:assignable) { described_class.new(definition, file_path) }

  describe 'class methods' do
    let(:another_assignable) do
      described_class.new({
        name: 'modify_resource',
        description: 'Grants action on other resource',
        permissions: %w[delete_other_resource write_other_resource]
      }, 'path/to/other_resource/modify.yml')
    end

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
        assignable.name => assignable,
        another_assignable.name => another_assignable
      })
    end

    describe '.all_permissions' do
      it 'returns all permissions across all assignables' do
        expect(described_class.all_permissions)
          .to match_array([*assignable.permissions, *another_assignable.permissions])
      end
    end

    describe '.for_permission' do
      it 'returns assignables that include the given permission' do
        expect(described_class.for_permission(:delete_other_resource))
          .to match_array([another_assignable])
      end
    end
  end

  it_behaves_like 'loadable yaml permission or permission group' do
    let(:definition_name) { :edit_wiki }
  end

  describe 'instance methods' do
    describe '#permissions' do
      it 'returns unique permissions as symbols' do
        expect(assignable.permissions).to match_array([:read_resource, :write_resource])
      end
    end

    describe '#category' do
      subject { assignable.category }

      context 'when not nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}resource/action.yml" }

        it 'returns feature_category' do
          is_expected.to eq('feature_category_name')
        end
      end

      context 'when nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}resource_category/resource/action.yml" }

        it 'returns the name of the category directory' do
          is_expected.to eq('resource_category')
        end
      end
    end
  end
end
