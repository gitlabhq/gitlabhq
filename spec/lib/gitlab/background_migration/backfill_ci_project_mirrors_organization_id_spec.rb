# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiProjectMirrorsOrganizationId,
  feature_category: :continuous_integration do
  let(:organizations) { table(:organizations, database: :main, primary_key: :id) }
  let(:namespaces) { table(:namespaces, database: :main, primary_key: :id) }
  let(:projects) { table(:projects, database: :main, primary_key: :id) }
  let(:ci_project_mirrors) { table(:ci_project_mirrors, database: :ci, primary_key: :id) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:other_organization) { organizations.create!(name: 'other', path: 'other') }

  let!(:group) { namespaces.create!(name: 'group', path: 'group', organization_id: organization.id) }

  let!(:project_namespace) do
    namespaces.create!(name: 'project', path: 'project', organization_id: organization.id)
  end

  let!(:other_project_namespace) do
    namespaces.create!(name: 'other-project', path: 'other-project', organization_id: other_organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:other_project) do
    projects.create!(
      name: 'other-project',
      path: 'other-project',
      namespace_id: group.id,
      project_namespace_id: other_project_namespace.id,
      organization_id: other_organization.id
    )
  end

  let!(:mirror_to_backfill) do
    ci_project_mirrors.create!(project_id: project.id, namespace_id: group.id)
  end

  let!(:mirror_already_set) do
    ci_project_mirrors.create!(
      project_id: other_project.id,
      namespace_id: group.id,
      organization_id: other_organization.id
    )
  end

  let!(:mirror_without_project) do
    ci_project_mirrors.create!(project_id: non_existing_record_id, namespace_id: group.id)
  end

  def perform_migration
    described_class.new(
      start_cursor: [ci_project_mirrors.minimum(:id)],
      end_cursor: [ci_project_mirrors.maximum(:id)],
      batch_table: :ci_project_mirrors,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    ).perform
  end

  describe '#perform' do
    it 'backfills organization_id from the mirrored project' do
      perform_migration

      expect(mirror_to_backfill.reload.organization_id).to eq(organization.id)
    end

    it 'backfills rows from different organizations with one UPDATE per sub-batch' do
      mirror_already_set.update!(organization_id: nil)

      recorder = ActiveRecord::QueryRecorder.new { perform_migration }

      expect(recorder.log.grep(/UPDATE ci_project_mirrors/).count).to eq(1)
      expect(mirror_to_backfill.reload.organization_id).to eq(organization.id)
      expect(mirror_already_set.reload.organization_id).to eq(other_organization.id)
    end

    it 'skips sub-batches where every row already has an organization_id' do
      ci_project_mirrors.update_all(organization_id: organization.id)

      recorder = ActiveRecord::QueryRecorder.new { perform_migration }

      expect(recorder.log.grep(/UPDATE ci_project_mirrors/)).to be_empty
      expect(recorder.log.grep(/FROM "projects"/)).to be_empty
    end

    it 'does not touch rows that already have an organization_id' do
      expect { perform_migration }
        .not_to change { mirror_already_set.reload.organization_id }
    end

    it 'leaves rows without a matching project unchanged' do
      perform_migration

      expect(mirror_without_project.reload.organization_id).to be_nil
    end
  end
end
