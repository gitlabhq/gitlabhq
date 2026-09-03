# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddRepairDualShardingKeyTriggerToNotes, feature_category: :team_planning do
  include Gitlab::Database::SchemaHelpers

  let(:connection) { ApplicationRecord.connection }
  let(:trigger_name) { 'trigger_817aa51bc4f2' }
  let(:function_name) { 'repair_dual_sharding_key_on_notes' }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:notes) { table(:notes) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let(:group_namespace) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:project_namespace) do
    namespaces.create!(
      name: 'test-project',
      path: 'test-project',
      type: 'Project',
      parent_id: group_namespace.id,
      organization_id: organization.id
    )
  end

  let(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      namespace_id: group_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  before do
    migrate!
  end

  describe 'BEFORE UPDATE trigger on notes' do
    context 'when a row has both namespace_id and project_id set (dual-key row)' do
      it 'nulls out namespace_id on UPDATE, leaving only project_id as the sharding key', :aggregate_failures do
        # Insert a dual-key row directly, bypassing the constraint that would
        # normally prevent this (the BBM leaves millions of such rows in place).
        note = notes.create!(
          noteable_type: 'Issue',
          note: 'dual-key note',
          project_id: project.id,
          namespace_id: group_namespace.id
        )

        # Simulate any plain UPDATE (e.g. bump_updated_at, resolve!, touch)
        note.update_columns(note: 'updated dual-key note')
        note.reload

        expect(note.namespace_id).to be_nil
        expect(note.project_id).to eq(project.id)
      end
    end

    context 'when a row has only project_id set (project-only row)' do
      it 'leaves sharding keys unchanged on UPDATE', :aggregate_failures do
        note = notes.create!(
          noteable_type: 'Issue',
          note: 'project-only note',
          project_id: project.id,
          namespace_id: nil
        )

        note.update_columns(note: 'updated project-only note')
        note.reload

        expect(note.namespace_id).to be_nil
        expect(note.project_id).to eq(project.id)
        expect(note.organization_id).to be_nil
      end
    end

    context 'when a row has only namespace_id set (namespace-only / group wiki row)' do
      it 'leaves sharding keys unchanged on UPDATE', :aggregate_failures do
        note = notes.create!(
          noteable_type: 'WikiPage::Meta',
          note: 'namespace-only note',
          namespace_id: group_namespace.id,
          project_id: nil
        )

        note.update_columns(note: 'updated namespace-only note')
        note.reload

        expect(note.namespace_id).to eq(group_namespace.id)
        expect(note.project_id).to be_nil
        expect(note.organization_id).to be_nil
      end
    end

    context 'when a row has only organization_id set (personal snippet / abuse-report note)' do
      it 'leaves sharding keys unchanged on UPDATE', :aggregate_failures do
        note = notes.create!(
          noteable_type: 'PersonalSnippet',
          note: 'org-only note',
          organization_id: organization.id,
          namespace_id: nil,
          project_id: nil
        )

        note.update_columns(note: 'updated org-only note')
        note.reload

        expect(note.organization_id).to eq(organization.id)
        expect(note.namespace_id).to be_nil
        expect(note.project_id).to be_nil
      end
    end
  end

  describe '#up', :aggregate_failures do
    it 'creates the trigger and function' do
      expect(trigger_exists?('notes', trigger_name)).to be(true)
      expect(function_exists?(function_name)).to be(true)
    end
  end

  describe '#down', :aggregate_failures do
    it 'removes the trigger and function' do
      schema_migrate_down!

      expect(trigger_exists?('notes', trigger_name)).to be(false)
      expect(function_exists?(function_name)).to be(false)
    end

    it 'no longer repairs dual-key rows on UPDATE' do
      schema_migrate_down!

      note = notes.create!(
        noteable_type: 'Issue',
        note: 'dual-key note',
        project_id: project.id,
        namespace_id: group_namespace.id
      )

      note.update_columns(note: 'updated dual-key note')
      note.reload

      expect(note.namespace_id).to eq(group_namespace.id)
      expect(note.project_id).to eq(project.id)
    end
  end
end
