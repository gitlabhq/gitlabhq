# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupDualShardingKeysInNotes,
  feature_category: :team_planning do
  let(:notes) { table(:notes) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let!(:namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', organization_id: organization.id)
  end

  let!(:project_namespace) do
    namespaces.create!(
      name: 'test-project',
      path: 'test-project',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let!(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      visibility_level: 0,
      organization_id: organization.id
    )
  end

  let!(:user) do
    users.find_or_create_by!(email: 'test@example.com') do |u|
      u.name = 'Test User'
      u.projects_limit = 10
      u.organization_id = organization.id
    end
  end

  let(:migration_attrs) do
    {
      start_cursor: [notes.minimum(:id)],
      end_cursor: [notes.maximum(:id)],
      batch_table: :notes,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'when a note has both namespace_id and project_id populated' do
      let!(:dual_key_note) do
        notes.create!(
          project_id: project.id,
          namespace_id: project_namespace.id,
          author_id: user.id,
          noteable_type: 'Issue',
          noteable_id: 1
        )
      end

      it 'sets namespace_id to NULL' do
        expect { migration.perform }
          .to change { dual_key_note.reload.namespace_id }.from(project_namespace.id).to(nil)
      end

      it 'preserves project_id' do
        expect { migration.perform }
          .not_to change { dual_key_note.reload.project_id }
      end
    end

    context 'when a note has only project_id (namespace_id already NULL)' do
      let!(:project_only_note) do
        notes.create!(
          project_id: project.id,
          namespace_id: nil,
          author_id: user.id,
          noteable_type: 'Issue',
          noteable_id: 1
        )
      end

      it 'does not change the note' do
        expect { migration.perform }
          .not_to change { project_only_note.reload.attributes }
      end
    end

    context 'when a note has only namespace_id (project_id is NULL)' do
      let!(:namespace_only_note) do
        notes.create!(
          project_id: nil,
          namespace_id: namespace.id,
          author_id: user.id,
          noteable_type: 'Epic',
          noteable_id: 1
        )
      end

      it 'does not change the note' do
        expect { migration.perform }
          .not_to change { namespace_only_note.reload.namespace_id }
      end
    end

    context 'when a note has neither project_id nor namespace_id' do
      let!(:org_only_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,
          author_id: user.id,
          noteable_type: 'Snippet',
          noteable_id: 1
        )
      end

      it 'does not change the note' do
        expect { migration.perform }
          .not_to change { org_only_note.reload.attributes }
      end
    end

    context 'with a mix of note types' do
      let!(:dual_key_note_1) do
        notes.create!(
          project_id: project.id,
          namespace_id: project_namespace.id,
          author_id: user.id,
          noteable_type: 'Issue',
          noteable_id: 1
        )
      end

      let!(:dual_key_note_2) do
        notes.create!(
          project_id: project.id,
          namespace_id: namespace.id,
          author_id: user.id,
          noteable_type: 'MergeRequest',
          noteable_id: 2
        )
      end

      let!(:project_only_note) do
        notes.create!(
          project_id: project.id,
          namespace_id: nil,
          author_id: user.id,
          noteable_type: 'Issue',
          noteable_id: 3
        )
      end

      let!(:namespace_only_note) do
        notes.create!(
          project_id: nil,
          namespace_id: namespace.id,
          author_id: user.id,
          noteable_type: 'Epic',
          noteable_id: 4
        )
      end

      it 'nulls namespace_id only on dual-populated rows' do
        migration.perform

        expect(dual_key_note_1.reload.namespace_id).to be_nil
        expect(dual_key_note_2.reload.namespace_id).to be_nil
        expect(project_only_note.reload.namespace_id).to be_nil
        expect(namespace_only_note.reload.namespace_id).to eq(namespace.id)
      end

      it 'preserves project_id on all rows' do
        migration.perform

        expect(dual_key_note_1.reload.project_id).to eq(project.id)
        expect(dual_key_note_2.reload.project_id).to eq(project.id)
        expect(project_only_note.reload.project_id).to eq(project.id)
        expect(namespace_only_note.reload.project_id).to be_nil
      end
    end

    context 'when called multiple times (idempotent)' do
      let!(:dual_key_note) do
        notes.create!(
          project_id: project.id,
          namespace_id: project_namespace.id,
          author_id: user.id,
          noteable_type: 'Issue',
          noteable_id: 1
        )
      end

      it 'can be run multiple times safely' do
        migration.perform
        expect(dual_key_note.reload.namespace_id).to be_nil

        migration.perform
        expect(dual_key_note.reload.namespace_id).to be_nil
      end
    end
  end
end
