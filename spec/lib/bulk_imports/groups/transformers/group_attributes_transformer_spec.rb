# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Transformers::GroupAttributesTransformer do
  describe '#transform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import, user: user) }

    let_it_be(:entity) do
      create(
        :bulk_import_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_name: 'destination-name-path',
        destination_namespace: parent.full_path
      )
    end

    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:data) do
      {
        'name' => 'Source Group Name',
        'path' => 'source-group-path',
        'full_path' => 'source/full/path',
        'visibility' => 'private',
        'project_creation_level' => 'developer',
        'subgroup_creation_level' => 'maintainer'
      }
    end

    subject { described_class.new }

    it 'returns original data with some keys transformed' do
      transformed_data = subject.transform(context, { 'name' => 'Name', 'description' => 'Description' })

      expect(transformed_data).to eq({
        'name' => 'Name',
        'description' => 'Description',
        'parent_id' => parent.id,
        'path' => 'destination-name-path'
      })
    end

    it 'transforms path from destination_name' do
      transformed_data = subject.transform(context, data)

      expect(transformed_data['path']).to eq(entity.destination_name)
    end

    it 'removes full path' do
      transformed_data = subject.transform(context, data)

      expect(transformed_data).not_to have_key('full_path')
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

      context 'when destination namespace is empty' do
        it 'does not set parent id' do
          entity.update!(destination_namespace: '')

          transformed_data = subject.transform(context, data)

          expect(transformed_data).not_to have_key('parent_id')
        end
      end
    end
  end
end
