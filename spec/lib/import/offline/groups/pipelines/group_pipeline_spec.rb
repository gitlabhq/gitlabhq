# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Groups::Pipelines::GroupPipeline, feature_category: :importers do
  describe '#run', :clean_gitlab_redis_shared_state do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent) { create(:group) }
    let_it_be(:bulk_import, freeze: false) { create(:bulk_import, user: user) }
    let_it_be(:destination_slug) { 'my-destination-group' }

    let_it_be_with_reload(:entity) do
      create(
        :bulk_import_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: destination_slug,
        destination_namespace: parent.full_path
      )
    end

    let_it_be_with_reload(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:group_data) do
      {
        'id' => 38,
        'name' => 'Source Group Name',
        'path' => 'source-group-path',
        'visibility_level' => 0,
        'project_creation_level' => 2,
        'subgroup_creation_level' => 1,
        'description' => 'Group Description',
        'emails_enabled' => false,
        'lfs_enabled' => false,
        'membership_lock' => true,
        'mentions_disabled' => true,
        'share_with_group_lock' => false,
        'require_two_factor_authentication' => false,
        'two_factor_grace_period' => 48,
        'request_access_enabled' => true,
        'traversal_ids' => [38],
        'organization_id' => 1
      }
    end

    subject(:pipeline) { described_class.new(context) }

    before_all do
      parent.add_owner(user)
    end

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: group_data)
        )
      end

      allow(pipeline).to receive(:set_source_objects_counter)
    end

    it 'imports new group into destination group', :aggregate_failures do
      pipeline.run

      imported_group = Group.find_by_path(destination_slug)

      expect(imported_group).not_to be_nil
      expect(imported_group.parent).to eq(parent)
      expect(imported_group.path).to eq(destination_slug)
      expect(imported_group.description).to eq(group_data['description'])
      expect(imported_group.visibility_level).to eq(group_data['visibility_level'])
      expect(imported_group.project_creation_level).to eq(group_data['project_creation_level'])
      expect(imported_group.subgroup_creation_level).to eq(group_data['subgroup_creation_level'])
      expect(imported_group.lfs_enabled?).to eq(group_data['lfs_enabled'])
      expect(imported_group.emails_enabled?).to eq(group_data['emails_enabled'])
      expect(imported_group.mentions_disabled?).to eq(group_data['mentions_disabled'])
      expect(imported_group.membership_lock?).to eq(group_data['membership_lock'])
    end

    it 'skips duplicates on pipeline rerun' do
      expect { pipeline.run }.to change { Group.count }.by(1)
      expect { pipeline.run }.not_to change { Group.count }
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }

    it 'has extractors' do
      expect(described_class.get_extractor).to eq(
        klass: BulkImports::Common::Extractors::JsonExtractor,
        options: { relation: BulkImports::FileTransfer::BaseConfig::SELF_RELATION }
      )
    end

    it 'includes prohibited attributes transformer' do
      expect(described_class.transformers).to contain_exactly(
        { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
        { klass: Import::Offline::Groups::Transformers::GroupAttributesTransformer, options: nil }
      )
    end

    it 'has loaders' do
      expect(described_class.get_loader).to eq(klass: BulkImports::Groups::Loaders::GroupLoader, options: nil)
    end

    it 'aborts on failure' do
      expect(described_class.abort_on_failure?).to be(true)
    end

    it 'sets its relation to "self"' do
      expect(described_class.relation).to eq(BulkImports::FileTransfer::BaseConfig::SELF_RELATION)
    end

    it 'is a file extraction pipeline' do
      expect(described_class.file_extraction_pipeline?).to be(true)
    end
  end

  describe '#after_run' do
    let_it_be(:user) { create(:user) }
    let_it_be(:bulk_import, freeze: false) { create(:bulk_import, user: user) }
    let_it_be(:entity, freeze: false) { create(:bulk_import_entity, :group_entity, bulk_import: bulk_import) }
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    subject(:pipeline) { described_class.new(context) }

    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      pipeline.after_run(nil)
    end
  end
end
