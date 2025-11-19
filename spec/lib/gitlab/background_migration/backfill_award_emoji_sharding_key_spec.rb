# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for backfill setup
RSpec.describe Gitlab::BackgroundMigration::BackfillAwardEmojiShardingKey, :migration_with_transaction, feature_category: :team_planning do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:notes) { table(:notes) }
  let(:award_emoji) { table(:award_emoji) }
  let(:award_emoji_archived) { table(:award_emoji_archived) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:user) do
    table(:users).create!(email: 'email@example.com', username: 'user1', projects_limit: 10,
      organization_id: organization.id)
  end

  let(:mr_namespace) do
    namespaces.create!(name: "mr", path: "mr", organization_id: organization.id)
  end

  let(:mr_project) do
    projects.create!(
      namespace_id: mr_namespace.id,
      project_namespace_id: mr_namespace.id,
      organization_id: organization.id
    )
  end

  let(:merge_request) do
    table(:merge_requests).create!(target_project_id: mr_project.id, target_branch: 'main', source_branch: 'not-main')
  end

  let(:issue_project_namespace) do
    namespaces.create!(name: "issue", path: "issue", organization_id: organization.id)
  end

  let(:issue_group) do
    namespaces.create!(name: 'issue_group', path: 'issue_group', organization_id: organization.id)
  end

  let(:issue_project) do
    projects.create!(
      namespace_id: issue_group.id,
      project_namespace_id: issue_project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:issue_work_item_type_id) { table(:work_item_types).find_by(name: 'Issue').id }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: issue_project_namespace.id,
      project_id: issue_project.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:issue_note) do
    notes.create!(
      project_id: issue_project.id,
      namespace_id: issue_group.id, # We have invalid namespaces like this one in production
      noteable_type: 'Issue',
      noteable_id: issue.id,
      author_id: user.id
    )
  end

  let(:epic_namespace) do
    namespaces.create!(name: "epic", path: "epic", organization_id: organization.id)
  end

  let(:epic) do
    table(:epics).create!(
      group_id: epic_namespace.id,
      author_id: user.id,
      iid: 1,
      title: 't',
      title_html: 't',
      issue_id: issue.id
    )
  end

  let(:snippet_namespace) do
    namespaces.create!(name: "snippet", path: "snippet", organization_id: organization.id)
  end

  let(:snippet_project) do
    projects.create!(
      namespace_id: snippet_namespace.id,
      project_namespace_id: snippet_namespace.id,
      organization_id: organization.id
    )
  end

  let(:project_snippet) do
    table(:snippets).create!(
      type: 'ProjectSnippet',
      author_id: user.id,
      project_id: snippet_project.id,
      title: 'Snippet1'
    )
  end

  let(:project_snippet_note) do
    notes.create!(
      project_id: project_snippet.project_id,
      noteable_type: 'Snippet',
      noteable_id: project_snippet.id,
      author_id: user.id
    )
  end

  let(:project_snippet_note_with_organization_id) do
    notes.create!(
      project_id: project_snippet.project_id,
      noteable_type: 'Snippet',
      noteable_id: project_snippet.id,
      author_id: user.id,
      organization_id: organization.id
    )
  end

  let(:personal_snippet) do
    table(:snippets).create!(
      type: 'PersonalSnippet',
      author_id: user.id,
      organization_id: organization.id,
      title: 'Snippet2'
    )
  end

  let(:personal_snippet_note) do
    notes.create!(
      organization_id: personal_snippet.organization_id,
      noteable_type: 'Snippet',
      noteable_id: personal_snippet.id,
      author_id: user.id
    )
  end

  let(:migration) do
    start_id, end_id = award_emoji.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :award_emoji,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  let(:mr_emoji) do
    award_emoji.create!(
      awardable_type: 'MergeRequest',
      awardable_id: merge_request.id
    )
  end

  let(:issue_emoji) do
    award_emoji.create!(
      awardable_type: 'Issue',
      awardable_id: issue.id
    )
  end

  let(:issue_note_emoji) do
    award_emoji.create!(
      awardable_type: 'Note',
      awardable_id: issue_note.id
    )
  end

  let(:epic_emoji) do
    award_emoji.create!(
      awardable_type: 'Epic',
      awardable_id: epic.id
    )
  end

  let(:project_snippet_emoji) do
    award_emoji.create!(
      awardable_type: 'Snippet',
      awardable_id: project_snippet.id
    )
  end

  let(:project_snippet_note_emoji) do
    award_emoji.create!(
      awardable_type: 'Note',
      awardable_id: project_snippet_note.id
    )
  end

  let(:personal_snippet_emoji) do
    award_emoji.create!(
      awardable_type: 'Snippet',
      awardable_id: personal_snippet.id
    )
  end

  let(:personal_snippet_note_emoji) do
    award_emoji.create!(
      awardable_type: 'Note',
      awardable_id: personal_snippet_note.id
    )
  end

  let(:project_snippet_note_emoji_with_organization_id) do
    award_emoji.create!(
      awardable_type: 'Note',
      awardable_id: project_snippet_note_with_organization_id.id
    )
  end

  let(:orphaned_emoji) do
    award_emoji.create!(
      awardable_type: 'Issue',
      awardable_id: non_existing_record_id
    )
  end

  subject(:migrate) { migration.perform }

  before do
    award_emoji.connection.execute(<<~SQL)
      ALTER TABLE award_emoji DROP CONSTRAINT check_8ef14b7067;
    SQL

    mr_emoji
    issue_emoji
    issue_note_emoji
    epic_emoji
    project_snippet_emoji
    project_snippet_note_emoji
    personal_snippet_emoji
    personal_snippet_note_emoji
    project_snippet_note_emoji_with_organization_id
    orphaned_emoji

    award_emoji.connection.execute(<<~SQL)
      ALTER TABLE award_emoji
        ADD CONSTRAINT check_8ef14b7067 CHECK ((num_nonnulls(namespace_id, organization_id) = 1)) NOT VALID;
    SQL
  end

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate
        # 5 queries per batch, 5 batches
      end.to make_queries_matching(/UPDATE "award_emoji"/, 25).and(
        make_queries_matching(/DELETE FROM "award_emoji"/, 5)
      )
    end

    it 'sets correct namespace_id in every record and archives orphaned records', :aggregate_failures do
      expect(award_emoji.all).to contain_exactly(
        have_attributes(id: mr_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: issue_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: issue_note_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: epic_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: project_snippet_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: project_snippet_note_emoji.id, namespace_id: nil, organization_id: nil),
        have_attributes(id: personal_snippet_emoji.id, organization_id: nil, namespace_id: nil),
        have_attributes(id: personal_snippet_note_emoji.id, organization_id: nil, namespace_id: nil),
        have_attributes(id: orphaned_emoji.id, organization_id: nil, namespace_id: nil),
        have_attributes(
          id: project_snippet_note_emoji_with_organization_id.id, organization_id: nil, namespace_id: nil
        )
      )

      expect do
        migrate
      end.to change { award_emoji.count }.by(-1).and(
        change { award_emoji_archived.count }.by(1)
      )

      expect(award_emoji.all).to contain_exactly(
        have_attributes(id: mr_emoji.id, namespace_id: mr_namespace.id, organization_id: nil),
        have_attributes(id: issue_emoji.id, namespace_id: issue_project_namespace.id, organization_id: nil),
        have_attributes(id: issue_note_emoji.id, namespace_id: issue_project_namespace.id, organization_id: nil),
        have_attributes(id: epic_emoji.id, namespace_id: epic_namespace.id, organization_id: nil),
        have_attributes(id: project_snippet_emoji.id, namespace_id: snippet_namespace.id, organization_id: nil),
        have_attributes(id: project_snippet_note_emoji.id, namespace_id: snippet_namespace.id, organization_id: nil),
        have_attributes(id: personal_snippet_emoji.id, organization_id: organization.id, namespace_id: nil),
        have_attributes(id: personal_snippet_note_emoji.id, organization_id: organization.id, namespace_id: nil),
        have_attributes(
          id: project_snippet_note_emoji_with_organization_id.id,
          organization_id: nil,
          namespace_id: snippet_namespace.id
        )
      )
      expect(award_emoji_archived.all).to contain_exactly(
        have_attributes(id: orphaned_emoji.id, awardable_id: non_existing_record_id, awardable_type: 'Issue')
      )
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
