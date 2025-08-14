# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for backfill setup
RSpec.describe Gitlab::BackgroundMigration::BackfillSentNotificationsAfterPartition, feature_category: :team_planning do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:sent_notifications) { table(:sent_notifications) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:p_sent_notifications) do
    partitioned_table(
      :p_sent_notifications,
      by: :partition,
      strategy: :sliding_list,
      next_partition_if: ->(_) {},
      detach_partition_if: ->(_) {}
    )
  end

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

  let(:issue_namespace) do
    namespaces.create!(name: "issue", path: "issue", organization_id: organization.id)
  end

  let(:issue_work_item_type_id) { table(:work_item_types).find_by(name: 'Issue').id }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: issue_namespace.id,
      work_item_type_id: issue_work_item_type_id
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
      title: 'Snippet3'
    )
  end

  let(:design_namespace) do
    namespaces.create!(name: "design", path: "design", organization_id: organization.id)
  end

  let(:design_project) do
    projects.create!(
      namespace_id: design_namespace.id,
      project_namespace_id: design_namespace.id,
      organization_id: organization.id
    )
  end

  let(:design) do
    table(:design_management_designs).create!(project_id: design_project.id, filename: 'final_v2.jpg', iid: 1)
  end

  let(:wiki_page_namespace) do
    namespaces.create!(name: "wiki", path: "wiki", organization_id: organization.id)
  end

  let(:wiki_page_project) do
    projects.create!(
      namespace_id: wiki_page_namespace.id,
      project_namespace_id: wiki_page_namespace.id,
      organization_id: organization.id
    )
  end

  let(:wpm_project) { table(:wiki_page_meta).create!(title: 'Backlog', project_id: wiki_page_project.id) }
  let(:wpm_group) { table(:wiki_page_meta).create!(title: 'Backlog', namespace_id: wiki_page_namespace.id) }

  let(:migration) do
    start_id, end_id = sent_notifications.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :sent_notifications,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  let!(:issue_notification) do
    sent_notifications.create!(
      noteable_type: 'Issue',
      noteable_id: issue.id,
      namespace_id: 0,
      reply_key: 'issue'
    )
  end

  let!(:mr_notification) do
    sent_notifications.create!(
      noteable_type: 'MergeRequest',
      noteable_id: merge_request.id,
      namespace_id: 0,
      reply_key: 'mr'
    )
  end

  let!(:epic_notification) do
    sent_notifications.create!(
      noteable_type: 'Epic',
      noteable_id: epic.id,
      namespace_id: 0,
      reply_key: 'epic'
    )
  end

  let!(:design_notification) do
    sent_notifications.create!(
      noteable_type: 'DesignManagement::Design',
      noteable_id: design.id,
      namespace_id: 0,
      reply_key: 'design'
    )
  end

  let(:commit_namespace) do
    namespaces.create!(name: "commit", path: "commit", organization_id: organization.id)
  end

  let(:commit_project) do
    projects.create!(
      namespace_id: commit_namespace.id,
      project_namespace_id: commit_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:commit_notification) do
    sent_notifications.create!(
      noteable_type: 'Commit',
      noteable_id: nil,
      commit_id: '15db82db72d40952d7bc929888a0164bec3cc4e4',
      namespace_id: 0,
      project_id: commit_project.id,
      reply_key: 'commit'
    )
  end

  let!(:wpm_project_notification) do
    sent_notifications.create!(
      noteable_type: 'WikiPage::Meta',
      noteable_id: wpm_project.id,
      namespace_id: 0,
      reply_key: 'wpmp'
    )
  end

  let!(:wpm_group_notification) do
    sent_notifications.create!(
      noteable_type: 'WikiPage::Meta',
      noteable_id: wpm_group.id,
      namespace_id: 0,
      reply_key: 'wpmg'
    )
  end

  let!(:snippet_notification) do
    sent_notifications.create!(
      noteable_type: 'ProjectSnippet',
      noteable_id: project_snippet.id,
      namespace_id: 0,
      reply_key: 'snippet'
    )
  end

  let(:notification_already_on_partitioned_table) do
    sent_notifications.create!(
      noteable_type: 'ProjectSnippet',
      noteable_id: project_snippet.id,
      namespace_id: 0,
      reply_key: 'existing_record'
    )
  end

  subject(:migrate) { migration.perform }

  before do
    # invalid type record should not be backfilled
    sent_notifications.create!(
      noteable_type: 'INVALID_TYPE',
      noteable_id: issue.id,
      namespace_id: 0,
      reply_key: 'invalid_record_s'
    )
    # valid type but missing record should not be backfilled
    sent_notifications.create!(
      noteable_type: 'Issue',
      noteable_id: -1,
      namespace_id: 0,
      reply_key: 'deleted_issue_id'
    )

    # delete all because the sync trigger will create all the test records
    p_sent_notifications.delete_all

    # Intentionally creating this record in both tables to test existing records don't make the insert fail because of
    # a unique constraint on the PK
    notification_already_on_partitioned_table
  end

  describe '#up' do
    it 'inserts records in batches' do
      expect do
        migrate
        # 11 records, 2 per batch, 6 batches, 7 queries per batch
      end.to make_queries_matching(/INSERT INTO p_sent_notifications/, 42)
    end

    it 'sets correct namespace_id in every record' do
      expect do
        migrate
      end.to change { p_sent_notifications.count }.from(1).to(9)

      expect(p_sent_notifications.all).to contain_exactly(
        have_attributes(id: issue_notification.id, namespace_id: issue_namespace.id),
        have_attributes(id: mr_notification.id, namespace_id: mr_namespace.id),
        have_attributes(id: epic_notification.id, namespace_id: epic_namespace.id),
        have_attributes(id: design_notification.id, namespace_id: design_namespace.id),
        have_attributes(id: commit_notification.id, namespace_id: commit_namespace.id),
        have_attributes(id: wpm_project_notification.id, namespace_id: wiki_page_namespace.id),
        have_attributes(id: wpm_group_notification.id, namespace_id: wiki_page_namespace.id),
        have_attributes(id: snippet_notification.id, namespace_id: snippet_namespace.id),
        # We do not update the namespace_id for records that made it to the partitioned table already.
        # Every record in the partitioned table is ALWAYS created with the right namespace_id
        have_attributes(id: notification_already_on_partitioned_table.id, namespace_id: 0)
      )
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
