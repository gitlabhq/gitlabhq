# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Entity, type: :model, feature_category: :importers do
  subject { described_class.new(group: Group.new) }

  describe 'associations' do
    it { is_expected.to belong_to(:bulk_import).required }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to belong_to(:group).with_foreign_key(:namespace_id).inverse_of(:bulk_import_entities) }
    it { is_expected.to belong_to(:project) }

    it do
      is_expected.to have_many(:trackers).class_name('BulkImports::Tracker')
        .with_foreign_key(:bulk_import_entity_id).inverse_of(:entity)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_type) }
    it { is_expected.to validate_presence_of(:source_full_path) }
    it { is_expected.to validate_presence_of(:destination_name) }

    it { is_expected.to define_enum_for(:source_type).with_values(%i[group_entity project_entity]) }

    context 'when source_type is group_entity' do
      subject { build(:bulk_import_entity, :group_entity) }

      it { is_expected.to allow_values('source', 'source/path', 'source/full/path').for(:source_full_path) }
      it { is_expected.not_to allow_values('/source', 'http://source/path', 'sou    rce/full/path', '').for(:source_full_path) }
    end

    context 'when source_type is project_entity' do
      subject { build(:bulk_import_entity, :project_entity) }

      it { is_expected.to allow_values('source/path', 'source/full/path').for(:source_full_path) }
      it { is_expected.not_to allow_values('/source', 'source', 'http://source/path', 'sou    rce/full/path', '').for(:source_full_path) }
    end

    context 'when associated with a group and project' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, group: build(:group), project: build(:project))

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:base, :project, :group)
      end
    end

    context 'when associated with a group and organization' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, organization: build(:organization), group: build(:group))

        expect(entity).not_to be_valid

        expect(entity.errors[:base])
          .to include('Import failed: Must have exactly one of organization, group or project.')
      end
    end

    context 'when associated with a project and organization' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, organization: build(:organization), project: build(:project))

        expect(entity).not_to be_valid

        expect(entity.errors[:base])
          .to include('Import failed: Must have exactly one of organization, group or project.')
      end
    end

    context 'when not associated with a group or project or organization' do
      it 'is not valid' do
        entity = build(:bulk_import_entity, group: nil, project: nil, organization: nil)

        expect(entity).not_to be_valid

        expect(entity.errors[:base])
          .to include('Import failed: Must have exactly one of organization, group or project.')
      end
    end

    context 'when associated with a group and no project or organization' do
      let(:associations) { { group: build(:group), project: nil, organization: nil } }

      it 'is valid as a group_entity' do
        entity = build(:bulk_import_entity, :group_entity, **associations)
        expect(entity).to be_valid
      end

      it 'is valid when destination_namespace is empty' do
        entity = build(:bulk_import_entity, :group_entity, **associations, destination_namespace: '')
        expect(entity).to be_valid
      end

      it 'is invalid when destination_namespace is nil' do
        entity = build(:bulk_import_entity, :group_entity, **associations, destination_namespace: nil)
        expect(entity).not_to be_valid
      end

      it 'is invalid when destination_slug is empty' do
        entity = build(:bulk_import_entity, :group_entity, **associations, destination_slug: '')
        expect(entity).not_to be_valid
      end

      it 'is invalid when destination_slug is nil' do
        entity = build(:bulk_import_entity, :group_entity, **associations, destination_slug: nil)
        expect(entity).not_to be_valid
      end

      it 'is invalid as a project_entity' do
        entity = build(:bulk_import_entity, :project_entity, **associations)

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:group)
      end
    end

    context 'when associated with a project and no group or organization' do
      let(:associations) { { project: build(:project), group: nil, organization: nil } }

      it 'is valid' do
        entity = build(:bulk_import_entity, :project_entity, **associations)

        expect(entity).to be_valid
      end

      it 'is invalid when destination_namespace is nil' do
        entity = build(:bulk_import_entity, :project_entity, **associations, destination_namespace: nil)
        expect(entity).not_to be_valid
        expect(entity.errors).to include(:destination_namespace)
      end

      it 'is invalid as a group_entity' do
        entity = build(:bulk_import_entity, :group_entity, **associations)

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:project)
      end
    end

    context 'when associated with an organization and no group or project' do
      let(:associations) { { project: nil, group: nil, organization: build(:organization) } }

      it 'is valid as a project_entity' do
        entity = build(:bulk_import_entity, :project_entity, **associations)

        expect(entity).to be_valid
      end

      it 'is valid as a group_entity' do
        entity = build(:bulk_import_entity, :group_entity, **associations)

        expect(entity).to be_valid
      end
    end

    context 'when the parent is a group import' do
      it 'is valid' do
        entity = build(:bulk_import_entity, parent: build(:bulk_import_entity, :group_entity))

        expect(entity).to be_valid
      end
    end

    context 'when the parent is a project import' do
      it 'is invalid' do
        entity = build(:bulk_import_entity, parent: build(:bulk_import_entity, :project_entity))

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:parent)
      end
    end

    context 'validate destination namespace of a group_entity' do
      it 'is invalid if destination namespace is the source namespace' do
        group_a = create(:group, path: 'group_a')

        entity = build(
          :bulk_import_entity,
          :group_entity,
          source_full_path: group_a.full_path,
          destination_namespace: group_a.full_path
        )

        expect(entity).not_to be_valid
        expect(entity.errors).to include(:base)
        expect(entity.errors[:base])
          .to include('Import failed: Destination cannot be a subgroup of the source group. Change the destination and try again.')
      end

      it 'is invalid if destination namespace is a descendant of the source' do
        group_a = create(:group, path: 'group_a')
        group_b = create(:group, parent: group_a, path: 'group_b')

        entity = build(
          :bulk_import_entity,
          :group_entity,
          source_full_path: group_a.full_path,
          destination_namespace: group_b.full_path
        )

        expect(entity).not_to be_valid
        expect(entity.errors[:base])
          .to include('Import failed: Destination cannot be a subgroup of the source group. Change the destination and try again.')
      end
    end

    context 'when source_type is a project_entity' do
      it 'is valid' do
        entity = build(:bulk_import_entity, :project_entity)

        expect(entity).to be_valid
      end
    end
  end

  describe '#encoded_source_full_path' do
    it 'encodes entity source full path' do
      expected = 'foo%2Fbar'
      entity = build(:bulk_import_entity, source_full_path: 'foo/bar')

      expect(entity.encoded_source_full_path).to eq(expected)
    end
  end

  describe 'scopes' do
    describe '.by_user_id' do
      it 'returns entities associated with specified user' do
        user = create(:user)
        import = create(:bulk_import, user: user)
        entity_1 = create(:bulk_import_entity, bulk_import: import)
        entity_2 = create(:bulk_import_entity, bulk_import: import)
        create(:bulk_import_entity)

        expect(described_class.by_user_id(user.id)).to contain_exactly(entity_1, entity_2)
      end
    end

    describe '.stale' do
      it 'returns entities that are stale' do
        entity_1 = create(:bulk_import_entity, updated_at: 3.days.ago)
        create(:bulk_import_entity)

        expect(described_class.stale).to contain_exactly(entity_1)
      end
    end

    describe '.order_by_updated_at_and_id' do
      it 'returns entities ordered by updated_at and id' do
        entity_1 = create(:bulk_import_entity, updated_at: 3.days.ago)
        entity_2 = create(:bulk_import_entity, updated_at: 2.days.ago)

        expect(described_class.order_by_updated_at_and_id(:desc)).to eq([entity_2, entity_1])
      end
    end
  end

  describe '.all_human_statuses' do
    it 'returns all human readable entity statuses' do
      expect(described_class.all_human_statuses)
        .to contain_exactly('created', 'started', 'finished', 'failed', 'timeout', 'canceled')
    end
  end

  describe '#pipelines' do
    context 'when entity is group' do
      it 'returns group pipelines' do
        entity = build(:bulk_import_entity, :group_entity)

        expect(entity.pipelines.collect { _1[:pipeline] }).to include(BulkImports::Groups::Pipelines::GroupPipeline)
      end
    end

    context 'when entity is project' do
      it 'returns project pipelines' do
        entity = build(:bulk_import_entity, :project_entity)

        expect(entity.pipelines.collect { _1[:pipeline] }).to include(BulkImports::Projects::Pipelines::ProjectPipeline)
      end
    end
  end

  describe '#pipeline_exists?' do
    let_it_be(:entity) { create(:bulk_import_entity, :group_entity) }

    it 'returns true when the given pipeline name exists in the pipelines list' do
      expect(entity.pipeline_exists?(BulkImports::Groups::Pipelines::GroupPipeline)).to eq(true)
      expect(entity.pipeline_exists?('BulkImports::Groups::Pipelines::GroupPipeline')).to eq(true)
    end

    it 'returns false when the given pipeline name exists in the pipelines list' do
      expect(entity.pipeline_exists?('BulkImports::Groups::Pipelines::InexistentPipeline')).to eq(false)
    end
  end

  describe '#pluralized_name' do
    context 'when entity is group' do
      it 'returns groups' do
        entity = build(:bulk_import_entity, :group_entity)

        expect(entity.pluralized_name).to eq('groups')
      end
    end

    context 'when entity is project' do
      it 'returns projects' do
        entity = build(:bulk_import_entity, :project_entity)

        expect(entity.pluralized_name).to eq('projects')
      end
    end
  end

  describe '#portable_class' do
    context 'when entity is group' do
      it 'returns Group class' do
        entity = build(:bulk_import_entity, :group_entity)

        expect(entity.portable_class).to eq(Group)
      end
    end

    context 'when entity is project' do
      it 'returns Project class' do
        entity = build(:bulk_import_entity, :project_entity)

        expect(entity.portable_class).to eq(Project)
      end
    end
  end

  describe '#export_relations_url_path' do
    context 'when entity is group' do
      it 'returns group export relations url' do
        entity = build(:bulk_import_entity, :group_entity)

        expect(entity.export_relations_url_path).to eq("/groups/#{entity.source_xid}/export_relations")
      end
    end

    context 'when entity is project' do
      it 'returns project export relations url' do
        entity = build(:bulk_import_entity, :project_entity)

        expect(entity.export_relations_url_path).to eq("/projects/#{entity.source_xid}/export_relations")
      end
    end

    context 'when batched' do
      context 'when source supports batched export' do
        it 'returns batched export relations url' do
          import = build(:bulk_import, source_version: '16.2.0')
          entity = build(:bulk_import_entity, :project_entity, bulk_import: import)

          expect(entity.export_relations_url_path).to eq("/projects/#{entity.source_xid}/export_relations?batched=true")
        end
      end

      context 'when source does not support batched export' do
        it 'returns export relations url' do
          entity = build(:bulk_import_entity)

          expect(entity.export_relations_url_path).to eq("/groups/#{entity.source_xid}/export_relations")
        end
      end
    end
  end

  describe '#relation_download_url_path' do
    it 'returns export relations url with download query string' do
      entity = build(:bulk_import_entity)

      expect(entity.relation_download_url_path('test'))
        .to eq("/groups/#{entity.source_xid}/export_relations/download?relation=test")
    end

    context 'when batch number is present' do
      context 'when source supports batched export' do
        it 'returns export relations url with download query string and batch number' do
          import = build(:bulk_import, source_version: '16.2.0')
          entity = build(:bulk_import_entity, :project_entity, bulk_import: import)

          expect(entity.relation_download_url_path('test', 1))
            .to eq("/projects/#{entity.source_xid}/export_relations/download?batch_number=1&batched=true&relation=test")
        end
      end

      context 'when source does not support batched export' do
        it 'returns export relations url' do
          entity = build(:bulk_import_entity)

          expect(entity.relation_download_url_path('test', 1))
            .to eq("/groups/#{entity.source_xid}/export_relations/download?relation=test")
        end
      end
    end
  end

  describe '#entity_type' do
    it 'returns entity type' do
      group_entity = build(:bulk_import_entity)
      project_entity = build(:bulk_import_entity, :project_entity)

      expect(group_entity.entity_type).to eq('group')
      expect(project_entity.entity_type).to eq('project')
    end
  end

  describe '#project?' do
    it 'returns true if project entity' do
      group_entity = build(:bulk_import_entity)
      project_entity = build(:bulk_import_entity, :project_entity)

      expect(group_entity.project?).to eq(false)
      expect(project_entity.project?).to eq(true)
    end
  end

  describe '#group?' do
    it 'returns true if group entity' do
      group_entity = build(:bulk_import_entity)
      project_entity = build(:bulk_import_entity, :project_entity)

      expect(group_entity.group?).to eq(true)
      expect(project_entity.group?).to eq(false)
    end
  end

  describe '#base_resource_url_path' do
    it 'returns base entity url path' do
      entity = build(:bulk_import_entity, source_xid: nil)

      expect(entity.base_resource_path).to eq("/groups/#{entity.encoded_source_full_path}")
    end
  end

  describe '#wiki_url_path' do
    it 'returns entity wiki url path' do
      entity = build(:bulk_import_entity, source_xid: nil)

      expect(entity.wikis_url_path).to eq("/groups/#{entity.encoded_source_full_path}/wikis")
    end
  end

  describe '#update_service' do
    it 'returns correct update service class' do
      group_entity = build(:bulk_import_entity)
      project_entity = build(:bulk_import_entity, :project_entity)

      expect(group_entity.update_service).to eq(::Groups::UpdateService)
      expect(project_entity.update_service).to eq(::Projects::UpdateService)
    end
  end

  describe '#full_path' do
    it 'returns group full path for group entity' do
      group_entity = build(:bulk_import_entity, :group_entity, group: build(:group))

      expect(group_entity.full_path).to eq(group_entity.group.full_path)
    end

    it 'returns project full path for project entity' do
      project_entity = build(:bulk_import_entity, :project_entity, project: build(:project))

      expect(project_entity.full_path).to eq(project_entity.project.full_path)
    end

    it 'returns nil when not associated with group or project' do
      entity = build(:bulk_import_entity, group: nil, project: nil)

      expect(entity.full_path).to eq(nil)
    end
  end

  describe '#full_path_with_fallback' do
    it 'returns group full path for group entity' do
      group_entity = build(:bulk_import_entity, :group_entity, group: build(:group))

      expect(group_entity.full_path_with_fallback).to eq(group_entity.group.full_path)
    end

    it 'returns project full path for project entity' do
      project_entity = build(:bulk_import_entity, :project_entity, project: build(:project))

      expect(project_entity.full_path_with_fallback).to eq(project_entity.project.full_path)
    end

    it 'returns fallback full path when not associated with group or project' do
      entity = build(:bulk_import_entity, group: nil, project: nil)

      expect(entity.full_path_with_fallback).to eq("#{entity.destination_namespace}/#{entity.destination_slug}")
    end
  end

  describe '#default_visibility_level' do
    context 'when entity is a group' do
      it 'returns default group visibility' do
        stub_application_setting(default_group_visibility: Gitlab::VisibilityLevel::PUBLIC)
        entity = build(:bulk_import_entity, :group_entity, group: build(:group))

        expect(entity.default_visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
      end
    end

    context 'when entity is a project' do
      it 'returns default project visibility' do
        stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
        entity = build(:bulk_import_entity, :project_entity, group: build(:group))

        expect(entity.default_visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end
  end

  describe '#update_has_failures' do
    let(:entity) { create(:bulk_import_entity) }

    context 'when entity has failures' do
      it 'sets has_failures flag to true' do
        expect(entity.has_failures).to eq(false)

        create(:bulk_import_failure, entity: entity)

        entity.fail_op!

        expect(entity.has_failures).to eq(true)
      end

      it 'sets the has_failures flag on the parent import' do
        create(:bulk_import_failure, entity: entity)

        expect { entity.update_has_failures }
          .to change { entity.bulk_import.has_failures? }.from(false).to(true)
      end
    end

    context 'when entity does not have failures' do
      it 'sets has_failures flag to false' do
        expect(entity.has_failures).to eq(false)

        entity.fail_op!

        expect(entity.has_failures).to eq(false)
      end
    end
  end

  describe '#source_version' do
    subject { build(:bulk_import_entity, :group_entity) }

    it 'pulls the source version from the associated BulkImport' do
      expect(subject.source_version).to eq(subject.bulk_import.source_version_info)
    end
  end

  describe '#checksums' do
    let(:entity) { create(:bulk_import_entity) }

    it 'returns checksums for all imported relations' do
      create(:bulk_import_tracker,
        entity: entity,
        relation: 'BulkImports::Common::Pipelines::MilestonesPipeline',
        source_objects_count: 7,
        fetched_objects_count: 6,
        imported_objects_count: 5
      )

      create(:bulk_import_tracker,
        entity: entity,
        relation: 'BulkImports::Common::Pipelines::LabelsPipeline',
        source_objects_count: 10,
        fetched_objects_count: 9,
        imported_objects_count: 8
      )

      expect(entity.checksums).to eq(
        {
          milestones: {
            source: 7,
            fetched: 6,
            imported: 5
          },
          labels: {
            source: 10,
            fetched: 9,
            imported: 8
          }
        }
      )
    end

    context 'when tracker should not be included' do
      let(:tracker) { create(:bulk_import_tracker, entity: entity, relation: 'BulkImports::Common::Pipelines::MilestonesPipeline') }

      context 'when tracker is for a file extraction pipeline' do
        it 'does not include the tracker' do
          expect(entity.checksums).to eq({})
        end
      end

      context 'when tracker is skipped' do
        it 'does not include the tracker' do
          tracker.skip!

          expect(entity.checksums).to eq({})
        end
      end

      context 'when tracker checksums are zeros' do
        it 'does not include the tracker' do
          tracker.update!(
            source_objects_count: 0,
            fetched_objects_count: 0,
            imported_objects_count: 0
          )

          expect(entity.checksums).to eq({})
        end
      end
    end
  end

  describe 'entity canceling' do
    let(:entity) { create(:bulk_import_entity, :started) }

    it 'marks entity as canceled' do
      entity.cancel!

      expect(entity.canceled?).to eq(true)
    end

    context 'when entity has trackers' do
      it 'marks trackers as canceled' do
        tracker = create(
          :bulk_import_tracker,
          entity: entity,
          relation: 'BulkImports::Common::Pipelines::MilestonesPipeline'
        )

        entity.cancel!

        expect(tracker.reload.canceled?).to eq(true)
      end
    end
  end
end
