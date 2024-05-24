# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Transformers::GroupAttributesTransformer, feature_category: :importers do
  describe '#transform' do
    let(:bulk_import) { build_stubbed(:bulk_import) }
    let(:destination_group) { create(:group) }
    let(:destination_namespace) { destination_group&.full_path }

    let(:entity) do
      build_stubbed(
        :bulk_import_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'destination-slug-path',
        destination_namespace: destination_namespace
      )
    end

    let(:tracker) { build_stubbed(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:data) do
      {
        'name' => 'Source Group Name',
        'description' => 'Source Group Description',
        'path' => 'source-group-path',
        'full_path' => 'source/full/path',
        'visibility' => 'private',
        'project_creation_level' => 'developer',
        'subgroup_creation_level' => 'maintainer',
        'emails_disabled' => true,
        'lfs_enabled' => false,
        'mentions_disabled' => true,
        'share_with_group_lock' => false,
        'require_two_factor_authentication' => false,
        'two_factor_grace_period' => 100,
        'request_access_enabled' => false
      }
    end

    subject(:transformed_data) { described_class.new.transform(context, data) }

    it 'returns original data with some keys transformed' do
      expect(transformed_data).to eq({
        'name' => 'Source Group Name',
        'description' => 'Source Group Description',
        'parent_id' => destination_group.id,
        'path' => entity.destination_slug,
        'visibility_level' => Gitlab::VisibilityLevel.string_options[data['visibility']],
        'project_creation_level' => Gitlab::Access.project_creation_string_options[data['project_creation_level']],
        'subgroup_creation_level' => Gitlab::Access.subgroup_creation_string_options[data['subgroup_creation_level']],
        'emails_enabled' => false,
        'lfs_enabled' => false,
        'mentions_disabled' => true,
        'share_with_group_lock' => false,
        'require_two_factor_authentication' => false,
        'two_factor_grace_period' => 100,
        'request_access_enabled' => false
      })
    end

    context 'when some fields are not present' do
      let(:data) do
        {
          'name' => 'Source Group Name',
          'description' => 'Source Group Description',
          'path' => 'source-group-path',
          'full_path' => 'source/full/path'
        }
      end

      it 'does not include those fields' do
        expect(transformed_data).to eq({
          'name' => 'Source Group Name',
          'path' => 'destination-slug-path',
          'description' => 'Source Group Description',
          'parent_id' => destination_group.id,
          'share_with_group_lock' => nil,
          'emails_enabled' => true,
          'lfs_enabled' => nil,
          'mentions_disabled' => nil
        })
      end
    end

    context 'when the destination_slug has invalid characters' do
      let(:entity) do
        build_stubbed(
          :bulk_import_entity,
          bulk_import: bulk_import,
          source_full_path: 'source/full/path',
          destination_slug: '____destination-_slug-path----__',
          destination_namespace: destination_namespace
        )
      end

      it 'normalizes the path' do
        expect(transformed_data[:path]).to eq('destination-slug-path')
      end
    end

    context 'when the destination_slug has . in the path' do
      let(:entity) do
        build_stubbed(
          :bulk_import_entity,
          bulk_import: bulk_import,
          source_full_path: 'source/full/path',
          destination_slug: 'Destination.slug-path.With-dots',
          destination_namespace: destination_namespace
        )
      end

      it 'normalizes the path but retains the .' do
        expect(transformed_data[:path]).to eq('destination.slug-path.with-dots')
      end
    end

    describe 'parent group transformation' do
      it 'sets parent id' do
        expect(transformed_data['parent_id']).to eq(destination_group.id)
      end

      context 'when destination namespace is empty' do
        before do
          entity.destination_namespace = ''
        end

        it 'does not set parent id' do
          expect(transformed_data).not_to have_key('parent_id')
        end
      end
    end

    context 'when destination namespace is empty' do
      before do
        entity.destination_namespace = ''
      end

      it 'does not transform name' do
        expect(transformed_data['name']).to eq('Source Group Name')
      end
    end

    context 'when destination namespace is present' do
      context 'when destination namespace does not have a group or project with same path' do
        it 'does not transform name' do
          expect(transformed_data['name']).to eq('Source Group Name')
        end
      end

      context 'when destination namespace already has a group or project with the same name' do
        before do
          create(:project, group: destination_group, name: 'Source Project Name', path: 'project')
          create(:group, parent: destination_group, name: 'Source Group Name', path: 'group')
          create(:group, parent: destination_group, name: 'Source Group Name_1', path: 'group_1')
          create(:group, parent: destination_group, name: 'Source Group Name_2', path: 'group_2')
        end

        it 'makes the name unique by appending a counter', :aggregate_failures do
          transformed_data = described_class.new.transform(context, data.merge('name' => 'Source Group Name'))
          expect(transformed_data['name']).to eq('Source Group Name_3')

          transformed_data = described_class.new.transform(context, data.merge('name' => 'Source Group Name_1'))
          expect(transformed_data['name']).to eq('Source Group Name_1_1')

          transformed_data = described_class.new.transform(context, data.merge('name' => 'Source Group Name_2'))
          expect(transformed_data['name']).to eq('Source Group Name_2_1')

          transformed_data = described_class.new.transform(context, data.merge('name' => 'Source Project Name'))
          expect(transformed_data['name']).to eq('Source Project Name_1')
        end
      end

      context 'when destination namespace already has a group or project with the same path' do
        before do
          create(:project, group: destination_group, name: 'Source Project Name', path: 'destination-slug-path')
          create(:group, parent: destination_group, name: 'Source Group Name_4', path: 'destination-slug-path_4')
          create(:group, parent: destination_group, name: 'Source Group Name_2', path: 'destination-slug-path_2')
          create(:group, parent: destination_group, name: 'Source Group Name_3', path: 'destination-slug-path_3')
        end

        it 'makes the path unique by appending a counter', :aggregate_failures do
          transformed_data = described_class.new.transform(context, data)
          expect(transformed_data['path']).to eq('destination-slug-path_1')

          create(:group, parent: destination_group, name: 'Source Group Name_1', path: 'destination-slug-path_1')

          transformed_data = described_class.new.transform(context, data)
          expect(transformed_data['path']).to eq('destination-slug-path_5')
        end
      end
    end

    describe 'visibility level' do
      include_examples 'visibility level settings'
    end
  end
end
