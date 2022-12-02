# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RenameTaskSystemNoteToChecklistItem do
  let(:notes) { table(:notes) }
  let(:projects) { table(:projects) }
  let(:namespace) { table(:namespaces).create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let(:issue_base_type_enum_value) { 0 }
  let(:issue_type) { table(:work_item_types).find_by!(namespace_id: nil, base_type: issue_base_type_enum_value) }

  let(:project) do
    table(:projects).create!(
      name: 'proj1', path: 'proj1', namespace_id: namespace.id, project_namespace_id: namespace.id
    )
  end

  let(:issue) do
    table(:issues).create!(
      title: 'Test issue', project_id: project.id,
      namespace_id: project.project_namespace_id, work_item_type_id: issue_type.id
    )
  end

  let!(:note1) do
    notes.create!(
      note: 'marked the task **Task 1** as complete', noteable_type: 'Issue', noteable_id: issue.id, system: true
    )
  end

  let!(:note2) do
    notes.create!(
      note: 'NO_MATCH marked the task **Task 2** as complete',
      noteable_type: 'Issue',
      noteable_id: issue.id,
      system: true
    )
  end

  let!(:note3) do
    notes.create!(
      note: 'marked the task **Task 3** as incomplete',
      noteable_type: 'Issue',
      noteable_id: issue.id,
      system: true
    )
  end

  let!(:note4) do
    notes.create!(
      note: 'marked the task **Task 4** as incomplete',
      noteable_type: 'Issue',
      noteable_id: issue.id,
      system: true
    )
  end

  let!(:metadata1) { table(:system_note_metadata).create!(note_id: note1.id, action: :task) }
  let!(:metadata2) { table(:system_note_metadata).create!(note_id: note2.id, action: :task) }
  let!(:metadata3) { table(:system_note_metadata).create!(note_id: note3.id, action: :task) }
  let!(:metadata4) { table(:system_note_metadata).create!(note_id: note4.id, action: :not_task) }

  let(:migration) do
    described_class.new(
      start_id: metadata1.id,
      end_id: metadata4.id,
      batch_table: :system_note_metadata,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) { migration.perform }

  it 'renames task to checklist item in task system notes that match', :aggregate_failures do
    expect do
      perform_migration

      note1.reload
      note2.reload
      note3.reload
      note4.reload
    end.to change(note1, :note).to('marked the checklist item **Task 1** as complete').and(
      not_change(note2, :note).from('NO_MATCH marked the task **Task 2** as complete')
    ).and(
      change(note3, :note).to('marked the checklist item **Task 3** as incomplete')
    ).and(
      not_change(note4, :note).from('marked the task **Task 4** as incomplete')
    )
  end

  it 'updates in batches' do
    expect { perform_migration }.to make_queries_matching(/UPDATE notes/, 2)
  end

  it 'tracks timings of queries' do
    expect(migration.batch_metrics.timings).to be_empty

    expect { perform_migration }.to change { migration.batch_metrics.timings }
  end
end
