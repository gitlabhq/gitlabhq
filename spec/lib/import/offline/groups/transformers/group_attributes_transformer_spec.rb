# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Groups::Transformers::GroupAttributesTransformer, feature_category: :importers do
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
        'id' => 38,
        'name' => 'Source Group Name',
        'path' => 'source-group-path',
        'description' => 'Source Group Description',
        'visibility_level' => 20,
        'project_creation_level' => 2,
        'subgroup_creation_level' => 1,
        'emails_enabled' => false,
        'lfs_enabled' => true,
        'membership_lock' => false,
        'mentions_disabled' => false,
        'share_with_group_lock' => false,
        'require_two_factor_authentication' => false,
        'two_factor_grace_period' => 48,
        'request_access_enabled' => true,
        'traversal_ids' => [38],
        'organization_id' => 1
      }
    end

    subject(:transformed_data) { described_class.new.transform(context, data) }

    it 'returns transformed data with allowed attributes' do
      expect(transformed_data).to eq({
        'name' => 'Source Group Name',
        'path' => entity.destination_slug,
        'parent_id' => destination_group.id,
        'description' => 'Source Group Description',
        'visibility_level' => 20,
        'project_creation_level' => 2,
        'subgroup_creation_level' => 1,
        'emails_enabled' => false,
        'lfs_enabled' => true,
        'membership_lock' => false,
        'mentions_disabled' => false,
        'share_with_group_lock' => false,
        'require_two_factor_authentication' => false,
        'two_factor_grace_period' => 48,
        'request_access_enabled' => true,
        'importing' => true
      })
    end

    it 'excludes all other attributes' do
      expect(transformed_data).not_to have_key('id')
      expect(transformed_data).not_to have_key('traversal_ids')
      expect(transformed_data).not_to have_key('organization_id')
    end

    context 'when data is nil' do
      let(:data) { nil }

      it { is_expected.to be_nil }
    end

    context 'when destination namespace is empty' do
      before do
        entity.destination_namespace = ''
      end

      it 'does not set parent id' do
        expect(transformed_data).not_to have_key('parent_id')
      end

      it 'does not transform name' do
        expect(transformed_data['name']).to eq('Source Group Name')
      end

      it 'still sets path from destination slug' do
        expect(transformed_data['path']).to eq(entity.destination_slug)
      end
    end

    context 'when destination namespace already has a group with the same name' do
      before do
        create(:group, parent: destination_group, name: 'Source Group Name', path: 'group')
        create(:group, parent: destination_group, name: 'Source Group Name_1', path: 'group_1')
      end

      it 'makes the name unique by appending a counter' do
        expect(transformed_data['name']).to eq('Source Group Name_2')
      end
    end

    context 'when destination namespace already has a group with the same path' do
      before do
        create(:group, parent: destination_group, name: 'Existing Group', path: 'destination-slug-path')
      end

      it 'makes the path unique by appending a counter' do
        expect(transformed_data['path']).to eq('destination-slug-path_1')
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

    describe 'visibility level' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:internal_group) { create(:group, :internal) }
      let_it_be(:private_group) { create(:group, :private) }

      let(:private) { Gitlab::VisibilityLevel::PRIVATE }
      let(:internal) { Gitlab::VisibilityLevel::INTERNAL }
      let(:public) { Gitlab::VisibilityLevel::PUBLIC }

      where(:visibility_level, :destination_group, :restricted_level, :expected) do
        ref(:public)   | ref(:public_group)   | nil             | ref(:public)
        ref(:public)   | ref(:public_group)   | ref(:public)    | ref(:internal)
        ref(:public)   | ref(:internal_group) | nil             | ref(:internal)
        ref(:public)   | ref(:private_group)  | nil             | ref(:private)
        ref(:internal) | ref(:public_group)   | nil             | ref(:internal)
        ref(:internal) | ref(:public_group)   | ref(:internal)  | ref(:private)
        ref(:internal) | ref(:internal_group) | nil             | ref(:internal)
        ref(:internal) | ref(:private_group)  | nil             | ref(:private)
        ref(:private)  | ref(:public_group)   | nil             | ref(:private)
        ref(:private)  | ref(:private_group)  | nil             | ref(:private)
      end

      with_them do
        let(:data) { { 'name' => 'Test', 'visibility_level' => visibility_level } }

        before do
          stub_application_setting(restricted_visibility_levels: [restricted_level])
        end

        it 'clamps visibility to the allowed level' do
          expect(transformed_data[:visibility_level]).to eq(expected)
        end
      end

      context 'when destination namespace is empty' do
        before do
          entity.destination_namespace = ''
        end

        it 'uses the source visibility level' do
          expect(transformed_data[:visibility_level]).to eq(data['visibility_level'])
        end
      end
    end
  end
end
