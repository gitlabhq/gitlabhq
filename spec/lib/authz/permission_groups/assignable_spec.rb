# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroups::Assignable, feature_category: :permissions do
  let(:definition) do
    {
      name: 'action_resource',
      description: 'Grants action on resource',
      feature_category: 'feature_category_name',
      # include read_resource twice to ensure uniqueness is handled
      permissions: %w[read_resource write_resource read_resource]
    }
  end

  let(:file_path) { 'path/to/resource/action.yml' }
  let(:assignable) { described_class.new(definition, file_path) }

  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :update_wiki }
  end

  it_behaves_like 'yaml backed permission'

  describe 'class methods' do
    let(:another_assignable) do
      described_class.new({
        name: 'modify_resource',
        description: 'Grants action on other resource',
        permissions: %w[write_resource delete_other_resource write_other_resource]
      }, 'path/to/other_resource/modify.yml')
    end

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
        assignable.name => assignable,
        another_assignable.name => another_assignable
      })
    end

    describe '.all_permissions' do
      it 'returns all unique permissions across all assignables' do
        unique_permissions = %i[read_resource write_resource delete_other_resource write_other_resource]
        expect(described_class.all_permissions).to match_array(unique_permissions)
      end
    end

    describe '.for_permission' do
      it 'returns assignables that include the given permission' do
        expect(described_class.for_permission(:delete_other_resource))
          .to match_array([another_assignable])
      end
    end
  end

  describe 'instance methods' do
    describe '#permissions' do
      it 'returns unique permissions as symbols' do
        expect(assignable.permissions).to match_array([:read_resource, :write_resource])
      end

      context 'when permissions key is missing from definition' do
        let(:definition) { { name: 'action_resource' } }

        it 'returns an empty array' do
          expect(assignable.permissions).to eq([])
        end
      end
    end

    describe '#category' do
      subject { assignable.category }

      context 'when not nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}/resource/action.yml" }

        it { is_expected.to eq('') }
      end

      context 'when nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}/resource_category/resource/action.yml" }

        it 'returns the name of the category directory' do
          is_expected.to eq('resource_category')
        end
      end
    end

    describe '#category_name' do
      subject { assignable.category_name }

      let(:file_path) { "#{described_class::BASE_PATH}/resource_category/resource/action.yml" }

      before do
        allow(Authz::PermissionGroups::Category).to receive(:get).and_return(nil)
      end

      context 'when category metadata does not exist' do
        it 'returns the category directory name titlecases' do
          is_expected.to eq('Resource Category')
        end
      end

      context 'when category metadata exists without a name' do
        let(:category_definition) do
          Authz::PermissionGroups::Category.new({}, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with('resource_category')
            .and_return(category_definition)
        end

        it 'returns the category directory name titlecased' do
          is_expected.to eq('Resource Category')
        end
      end

      context 'when category metadata exists with a name' do
        let(:category_definition) do
          Authz::PermissionGroups::Category.new({ name: 'Resource Category Display Name' }, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with('resource_category')
            .and_return(category_definition)
        end

        it 'returns the name from category metadata' do
          is_expected.to eq('Resource Category Display Name')
        end
      end
    end

    describe '#resource_definition' do
      let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/action.yml').to_s }
      let(:resource_def) { instance_double(Authz::PermissionGroups::Resource) }

      before do
        allow(Authz::PermissionGroups::Resource).to receive(:get)
          .with('ci_cd/pipeline')
          .and_return(resource_def)
      end

      it 'returns the resource definition for the category and resource' do
        expect(assignable.send(:resource_definition)).to eq(resource_def)
      end

      context 'when not nested under a category directory' do
        let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'pipeline/action.yml').to_s }

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('/pipeline')
            .and_return(resource_def)
        end

        it 'returns the resource definition with empty category' do
          expect(assignable.send(:resource_definition)).to eq(resource_def)
        end
      end
    end
  end
end
