# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissingNamespaceIdOnNotes, feature_category: :code_review_workflow do
  # Core tables
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }
  let(:issues) { table(:issues) }
  let(:merge_requests) { table(:merge_requests) }
  let(:alert_management_alerts) { table(:alert_management_alerts) }
  let(:epics) { table(:epics) }
  let(:snippets) { table(:snippets) }
  let(:wiki_page_meta) { table(:wiki_page_meta) }
  let(:work_item_types) { table(:work_item_types) }

  # Seed data
  let(:organization) do
    organizations.find_or_create_by!(path: 'default') do |org|
      org.name = 'default'
    end
  end

  let(:user_1) do
    users.find_or_create_by!(email: 'bob@example.com') do |user|
      user.name = 'bob'
      user.projects_limit = 1
      user.organization_id = organization.id
    end
  end

  let(:namespace_1) do
    namespaces.create!(
      name: 'namespace',
      path: 'namespace-path-1',
      organization_id: organization.id
    )
  end

  let(:project_namespace_2) do
    namespaces.create!(
      name: 'namespace',
      path: 'namespace-path-2',
      type: 'Project',
      organization_id: organization.id
    )
  end

  let!(:project_1) do
    projects.create!(
      name: 'project1',
      path: 'path1',
      namespace_id: namespace_1.id,
      project_namespace_id: project_namespace_2.id,
      visibility_level: 0,
      organization_id: organization.id
    )
  end

  # Helpers
  def create_work_item_type(name: "Type #{SecureRandom.hex}", id: nil)
    work_item_types.create!(
      id: id || SecureRandom.random_number(1_000_000),
      name: name
    )
  end

  def create_issue(title:, namespace:, author: user_1)
    work_item_type = create_work_item_type
    issues.create!(
      title: title,
      author_id: author.id,
      namespace_id: namespace.id,
      work_item_type_id: work_item_type.id
    )
  end

  def create_epic(group_namespace:, title: 'Example Epic')
    epic_issue = create_issue(title: 'Epic Issue', namespace: group_namespace)
    epics.create!(
      title: title,
      group_id: group_namespace.id,
      author_id: user_1.id,
      iid: SecureRandom.random_number(10_000),
      title_html: '<blink>Example</blink>',
      issue_id: epic_issue.id
    )
  end

  def create_snippet(author: user_1)
    snippets.create!(
      author_id: author.id,
      project_id: nil,
      organization_id: organization.id
    )
  end

  # Subject
  subject(:migration) do
    described_class.new(
      start_id: notes.minimum(:id),
      end_id: notes.maximum(:id),
      batch_table: :notes,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    after do
      # Clean up any archived notes after each test
      if ApplicationRecord.connection.table_exists?(:notes_archived)
        ApplicationRecord.connection.execute('TRUNCATE TABLE notes_archived')
      end
    end

    context 'with notes_archived table dependency' do
      it 'expects notes_archived table to exist' do
        expect(ApplicationRecord.connection.table_exists?(:notes_archived)).to be true
      end

      it 'expects notes_archived table to have archived_at column' do
        columns = ApplicationRecord.connection.columns(:notes_archived).map(&:name)
        expect(columns).to include('archived_at')
      end
    end

    context 'when processing Issue notes' do
      let!(:issue) { create_issue(title: 'Example Issue', namespace: namespace_1) }
      let!(:issue_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'Issue',
          noteable_id: issue.id,
          author_id: user_1.id
        )
      end

      it "updates namespace_id from Issue's namespace_id" do
        expect(issue_note.namespace_id).to be_nil

        migration.perform

        issue_note.reload
        expect(issue_note.namespace_id).to eq(namespace_1.id)
      end

      it 'uses efficient queries' do
        recorder = ActiveRecord::QueryRecorder.new { migration.perform }

        update_queries = recorder.log.select { |q| q.include?('UPDATE notes') }
        expect(update_queries.size).to eq(1)
      end
    end

    context 'when processing MergeRequest notes' do
      let!(:merge_request) do
        merge_requests.create!(
          target_project_id: project_1.id,
          source_project_id: project_1.id,
          target_branch: 'main',
          source_branch: 'feature',
          author_id: user_1.id
        )
      end

      let!(:mr_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'MergeRequest',
          noteable_id: merge_request.id,
          author_id: user_1.id
        )
      end

      it "updates namespace_id from MergeRequest's target_project namespace" do
        expect(mr_note.namespace_id).to be_nil

        migration.perform

        mr_note.reload
        expect(mr_note.namespace_id).to eq(project_namespace_2.id)
      end
    end

    context 'when processing AlertManagement::Alert notes' do
      let!(:alert) do
        alert_management_alerts.create!(
          project_id: project_1.id,
          started_at: Time.current,
          fingerprint: SecureRandom.hex,
          iid: 1,
          title: 'Test Alert'
        )
      end

      let!(:alert_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'AlertManagement::Alert',
          noteable_id: alert.id,
          author_id: user_1.id
        )
      end

      it "updates namespace_id from Alert's project namespace" do
        expect(alert_note.namespace_id).to be_nil

        migration.perform

        alert_note.reload
        expect(alert_note.namespace_id).to eq(project_namespace_2.id)
      end
    end

    context 'when processing Epic notes' do
      let!(:group_namespace) do
        namespaces.create!(
          name: 'group-namespace',
          path: 'group-namespace-path',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:epic) { create_epic(group_namespace: group_namespace) }
      let!(:epic_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'Epic',
          noteable_id: epic.id,
          author_id: user_1.id
        )
      end

      it "updates namespace_id from Epic's group_id" do
        expect(epic_note.namespace_id).to be_nil

        migration.perform

        epic_note.reload
        expect(epic_note.namespace_id).to eq(group_namespace.id)
      end
    end

    context 'when processing Snippet notes' do
      let!(:snippet) { create_snippet(author: user_1) }
      let!(:snippet_note) do
        notes.create!(
          author_id: user_1.id,
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Already present, keep it
          noteable_type: 'Snippet',
          noteable_id: snippet.id
        )
      end

      it "sets namespace_id to NULL and keeps organization_id for personal snippets" do
        expect(snippet_note.namespace_id).to be_nil
        expect(snippet_note.organization_id).to eq(organization.id)

        migration.perform

        snippet_note.reload
        expect(snippet_note.namespace_id).to be_nil
        expect(snippet_note.organization_id).to eq(organization.id)
      end

      it "does not archive personal snippet notes as orphans" do
        expect { migration.perform }.not_to change { notes.count }
      end
    end

    context 'when processing WikiPage::Meta notes' do
      let!(:group_namespace) do
        namespaces.create!(
          name: 'group-namespace-wiki',
          path: 'group-namespace-wiki-path',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:wiki_page_meta_for_project) do
        wiki_page_meta.create!(
          project_id: project_1.id,
          namespace_id: nil,
          title: 'Project Wiki Page'
        )
      end

      let!(:wiki_page_meta_for_group) do
        wiki_page_meta.create!(
          project_id: nil,
          namespace_id: group_namespace.id,
          title: 'Group Wiki Page'
        )
      end

      let!(:project_wiki_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'WikiPage::Meta',
          noteable_id: wiki_page_meta_for_project.id,
          author_id: user_1.id
        )
      end

      let!(:group_wiki_note) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'WikiPage::Meta',
          noteable_id: wiki_page_meta_for_group.id,
          author_id: user_1.id
        )
      end

      it 'updates both project and group wiki notes correctly' do
        migration.perform

        project_wiki_note.reload
        expect(project_wiki_note.namespace_id).to eq(project_namespace_2.id)

        group_wiki_note.reload
        expect(group_wiki_note.namespace_id).to eq(group_namespace.id)
      end
    end

    context 'with namespace_id correction' do
      let!(:issue) { create_issue(title: 'Example Issue', namespace: namespace_1) }
      let!(:wrong_namespace) do
        namespaces.create!(
          name: 'wrong-namespace',
          path: 'wrong-namespace-path',
          organization_id: organization.id
        )
      end

      let!(:note_with_wrong_namespace) do
        notes.create!(
          project_id: nil,
          namespace_id: wrong_namespace.id, # Has WRONG namespace
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'Issue',
          noteable_id: issue.id,
          author_id: user_1.id
        )
      end

      let!(:note_without_namespace) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'Issue',
          noteable_id: issue.id,
          author_id: user_1.id
        )
      end

      let!(:note_with_project) do
        notes.create!(
          project_id: project_1.id,
          namespace_id: nil,
          organization_id: nil, # Can be nil since project_id is set
          noteable_type: 'Issue',
          noteable_id: issue.id,
          author_id: user_1.id
        )
      end

      it 'corrects wrong namespace_id and fills missing ones' do
        migration.perform

        note_with_wrong_namespace.reload
        expect(note_with_wrong_namespace.namespace_id).to eq(namespace_1.id)

        note_without_namespace.reload
        expect(note_without_namespace.namespace_id).to eq(namespace_1.id)

        note_with_project.reload
        expect(note_with_project.namespace_id).to be_nil # Not touched (has project_id)
      end
    end

    context 'when archiving orphaned notes' do
      let!(:orphaned_note_1) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'UnknownType',
          noteable_id: 999_999,
          note: 'This is an orphaned note',
          author_id: user_1.id
        )
      end

      let!(:orphaned_note_2) do
        notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id,  # Added to satisfy constraint
          noteable_type: 'Issue',
          noteable_id: 999_999, # Non-existent issue
          note: 'Another orphaned note',
          author_id: user_1.id
        )
      end

      it 'archives and deletes orphaned notes' do
        expect(Gitlab::BackgroundMigration::Logger).to receive(:warn).at_least(:twice)
        expect(Gitlab::BackgroundMigration::Logger).to receive(:info).with(
          hash_including(message: 'Archived and deleted orphaned notes')
        )

        initial_count = notes.count
        orphaned_ids = [orphaned_note_1.id, orphaned_note_2.id]

        migration.perform

        expect(notes.count).to eq(initial_count - 2)
        expect { orphaned_note_1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { orphaned_note_2.reload }.to raise_error(ActiveRecord::RecordNotFound)

        archived_notes = ApplicationRecord.connection.select_all(
          'SELECT id, archived_at FROM notes_archived ORDER BY id'
        )
        expect(archived_notes.count).to eq(2)
        expect(archived_notes.rows.map(&:first)).to match_array(orphaned_ids)
      end
    end

    context 'with mixed noteable types' do
      let!(:issue) { create_issue(title: 'Example Issue', namespace: namespace_1) }
      let!(:merge_request) do
        merge_requests.create!(
          target_project_id: project_1.id,
          source_project_id: project_1.id,
          target_branch: 'main',
          source_branch: 'feature',
          author_id: user_1.id
        )
      end

      let!(:issue_notes) do
        Array.new(5) do
          notes.create!(
            project_id: nil,
            namespace_id: nil,
            organization_id: organization.id,  # Added to satisfy constraint
            noteable_type: 'Issue',
            noteable_id: issue.id,
            author_id: user_1.id
          )
        end
      end

      let!(:mr_notes) do
        Array.new(3) do
          notes.create!(
            project_id: nil,
            namespace_id: nil,
            organization_id: organization.id,  # Added to satisfy constraint
            noteable_type: 'MergeRequest',
            noteable_id: merge_request.id,
            author_id: user_1.id
          )
        end
      end

      it 'updates all notes efficiently' do
        recorder = ActiveRecord::QueryRecorder.new { migration.perform }

        issue_notes.each do |note|
          note.reload
          expect(note.namespace_id).to eq(namespace_1.id)
        end

        mr_notes.each do |note|
          note.reload
          expect(note.namespace_id).to eq(project_namespace_2.id)
        end

        # Should have one UPDATE per noteable type
        update_queries = recorder.log.select { |q| q.include?('UPDATE notes') }
        expect(update_queries.size).to eq(2)
      end
    end

    context 'with error recovery' do
      it 'continues processing if archiving fails' do
        orphaned_note = notes.create!(
          project_id: nil,
          namespace_id: nil,
          organization_id: organization.id, # Added to satisfy constraint
          noteable_type: 'UnknownType',
          noteable_id: 999_999,
          author_id: user_1.id
        )

        allow(ApplicationRecord.connection).to receive(:execute).and_call_original
        allow(ApplicationRecord.connection).to receive(:execute)
                                                 .with(/DELETE FROM notes/).and_raise(StandardError, 'Deletion failed')

        expect(Gitlab::BackgroundMigration::Logger).to receive(:error).with(
          hash_including(message: 'Failed to archive orphaned notes')
        )

        expect { migration.perform }.to raise_error(StandardError, 'Deletion failed')

        # Verify the note wasn't deleted due to the error
        expect { orphaned_note.reload }.not_to raise_error
      end
    end

    context 'with empty batches' do
      it 'handles empty batches gracefully' do
        empty_migration = described_class.new(
          start_id: 1_000_000,
          end_id: 1_000_100,
          batch_table: :notes,
          batch_column: :id,
          sub_batch_size: 10,
          pause_ms: 0,
          connection: ApplicationRecord.connection
        )

        expect { empty_migration.perform }.not_to raise_error
      end
    end

    context 'with large batches' do
      before do
        10.times do
          issue = create_issue(title: "Issue #{SecureRandom.hex}", namespace: namespace_1)
          notes.create!(
            project_id: nil,
            namespace_id: nil,
            organization_id: organization.id, # Added to satisfy constraint
            noteable_type: 'Issue',
            noteable_id: issue.id,
            author_id: user_1.id
          )
        end
      end

      it 'processes all notes efficiently' do
        expect { migration.perform }.to change {
          notes.where.not(namespace_id: nil).count
        }.by(10)

        notes.where(noteable_type: 'Issue').find_each do |note|
          expect(note.namespace_id).to eq(namespace_1.id)
        end
      end
    end
  end
end
