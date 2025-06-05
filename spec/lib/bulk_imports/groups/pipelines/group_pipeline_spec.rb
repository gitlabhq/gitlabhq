# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::GroupPipeline, feature_category: :importers do
  describe '#run', :clean_gitlab_redis_shared_state do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import, user: user) }
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
        'name' => 'Source Group Name',
        'full_path' => 'source/full/path',
        'visibility' => 'private',
        'project_creation_level' => 'developer',
        'subgroup_creation_level' => 'maintainer',
        'description' => 'Group Description',
        'emails_disabled' => true,
        'lfs_enabled' => false,
        'mentions_disabled' => true
      }
    end

    subject { described_class.new(context) }

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: group_data))
      end

      allow(subject).to receive(:set_source_objects_counter)

      parent.add_owner(user)
    end

    it 'imports new group into destination group' do
      subject.run

      imported_group = Group.find_by_path(destination_slug)

      expect(imported_group).not_to be_nil
      expect(imported_group.parent).to eq(parent)
      expect(imported_group.path).to eq(destination_slug)
      expect(imported_group.description).to eq(group_data['description'])
      expect(imported_group.visibility).to eq(group_data['visibility'])
      expect(imported_group.project_creation_level).to eq(Gitlab::Access.project_creation_string_options[group_data['project_creation_level']])
      expect(imported_group.subgroup_creation_level).to eq(Gitlab::Access.subgroup_creation_string_options[group_data['subgroup_creation_level']])
      expect(imported_group.lfs_enabled?).to eq(group_data['lfs_enabled'])
      expect(imported_group.emails_disabled?).to eq(group_data['emails_disabled'])
      expect(imported_group.mentions_disabled?).to eq(group_data['mentions_disabled'])
    end

    it 'skips duplicates on pipeline rerun' do
      expect { subject.run }.to change { Group.count }.by(1)
      expect { subject.run }.not_to change { Group.count }
    end

    it 'does not send an email to owner on group creation' do
      group_data['emails_disabled'] = false
      allow(Notify).to receive(:member_access_granted_email).and_call_original

      subject.run

      imported_group_owner = Group.find_by_path(destination_slug).all_owner_members.first

      expect(Notify)
        .not_to have_received(:member_access_granted_email)
        .with(imported_group_owner.real_source_type, imported_group_owner.id)
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: {
            query: BulkImports::Groups::Graphql::GetGroupQuery
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
          { klass: BulkImports::Groups::Transformers::GroupAttributesTransformer, options: nil }
        )
    end

    it 'has loaders' do
      expect(described_class.get_loader).to eq(klass: BulkImports::Groups::Loaders::GroupLoader, options: nil)
    end
  end
end
