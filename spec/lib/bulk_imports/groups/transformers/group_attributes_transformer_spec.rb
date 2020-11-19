# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Transformers::GroupAttributesTransformer do
  describe '#transform' do
    let(:user) { create(:user) }
    let(:parent) { create(:group) }
    let(:group) { create(:group, name: 'My Source Group', parent: parent) }
    let(:entity) do
      instance_double(
        BulkImports::Entity,
        source_full_path: 'source/full/path',
        destination_name: group.name,
        destination_namespace: parent.full_path
      )
    end

    let(:context) do
      instance_double(
        BulkImports::Pipeline::Context,
        current_user: user,
        entity: entity
      )
    end

    let(:data) do
      {
        'name' => 'source_name',
        'full_path' => 'source/full/path',
        'visibility' => 'private',
        'project_creation_level' => 'developer',
        'subgroup_creation_level' => 'maintainer'
      }
    end

    subject { described_class.new }

    it 'transforms name to destination name' do
      transformed_data = subject.transform(context, data)

      expect(transformed_data['name']).not_to eq('source_name')
      expect(transformed_data['name']).to eq(group.name)
    end

    it 'removes full path' do
      transformed_data = subject.transform(context, data)

      expect(transformed_data).not_to have_key('full_path')
    end

    it 'transforms path to parameterized name' do
      transformed_data = subject.transform(context, data)

      expect(transformed_data['path']).to eq(group.name.parameterize)
    end

    it 'transforms visibility level' do
      visibility = data['visibility']
      transformed_data = subject.transform(context, data)

      expect(transformed_data).not_to have_key('visibility')
      expect(transformed_data['visibility_level']).to eq(Gitlab::VisibilityLevel.string_options[visibility])
    end

    it 'transforms project creation level' do
      level = data['project_creation_level']
      transformed_data = subject.transform(context, data)

      expect(transformed_data['project_creation_level']).to eq(Gitlab::Access.project_creation_string_options[level])
    end

    it 'transforms subgroup creation level' do
      level = data['subgroup_creation_level']
      transformed_data = subject.transform(context, data)

      expect(transformed_data['subgroup_creation_level']).to eq(Gitlab::Access.subgroup_creation_string_options[level])
    end

    describe 'parent group transformation' do
      it 'sets parent id' do
        transformed_data = subject.transform(context, data)

        expect(transformed_data['parent_id']).to eq(parent.id)
      end

      context 'when destination namespace is user namespace' do
        let(:entity) do
          instance_double(
            BulkImports::Entity,
            source_full_path: 'source/full/path',
            destination_name: group.name,
            destination_namespace: user.namespace.full_path
          )
        end

        it 'does not set parent id' do
          transformed_data = subject.transform(context, data)

          expect(transformed_data).not_to have_key('parent_id')
        end
      end
    end
  end
end
