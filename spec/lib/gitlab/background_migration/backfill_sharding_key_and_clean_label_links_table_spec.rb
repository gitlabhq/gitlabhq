# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Necessary for backfill setup
RSpec.describe Gitlab::BackgroundMigration::BackfillShardingKeyAndCleanLabelLinksTable, feature_category: :team_planning do
  let(:label_links) { table(:label_links) }
  let(:label_links_archived) { table(:label_links_archived) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:project_namespace) do
    table(:namespaces).create!(name: "project1", path: "project1", organization_id: organization.id)
  end

  let(:label_namespace) do
    table(:namespaces).create!(name: "labelGroup", path: "labelg", organization_id: organization.id)
  end

  let(:label1) { table(:labels).create!(title: 'label1', color: '#990000', group_id: label_namespace.id) }
  let(:label2) { table(:labels).create!(title: 'label2', color: '#990000', group_id: label_namespace.id) }

  let(:issue_namespace) do
    table(:namespaces).create!(name: 'issue_group', path: 'issue_group', organization_id: organization.id)
  end

  let(:project_group) do
    table(:namespaces).create!(name: 'project_group', path: 'project_group', organization_id: organization.id)
  end

  let(:epic_namespace) do
    table(:namespaces).create!(name: 'group2', path: 'group2', organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(
      namespace_id: project_group.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:mr) do
    table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'not-main')
  end

  let(:issue_work_item_type_id) { 1 }
  let(:issue) do
    table(:issues).create!(
      title: 'First issue',
      iid: 1,
      namespace_id: issue_namespace.id,
      work_item_type_id: issue_work_item_type_id
    )
  end

  let(:user) do
    table(:users).create!(
      username: 'john_doe',
      email: 'johndoe@gitlab.com',
      projects_limit: 2,
      organization_id: organization.id
    )
  end

  let(:epic) do
    table(:epics).create!(
      iid: 1,
      group_id: epic_namespace.id,
      author_id: user.id,
      title: 't',
      title_html: 't',
      issue_id: issue.id
    )
  end

  let!(:issue_label_link1) { label_links.create!(target_type: 'Issue', target_id: issue.id, label_id: label1.id) }
  let!(:issue_label_link2) { label_links.create!(target_type: 'Issue', target_id: issue.id, label_id: label2.id) }
  let!(:invalid_label_link1) do
    label_links.create!(target_type: 'Issue', target_id: non_existing_record_id, label_id: label1.id)
  end

  let!(:invalid_label_link2) do
    label_links.create!(target_type: 'Issue', target_id: issue.id, label_id: nil)
  end

  let!(:mr_label_link1) { label_links.create!(target_type: 'MergeRequest', target_id: mr.id, label_id: label1.id) }
  let!(:mr_label_link2) { label_links.create!(target_type: 'MergeRequest', target_id: mr.id, label_id: label2.id) }
  let!(:invalid_label_link3) do
    label_links.create!(target_type: 'MergeRequest', target_id: non_existing_record_id, label_id: label1.id)
  end

  let!(:invalid_label_link4) do
    label_links.create!(target_type: 'MergeRequest', target_id: mr.id, label_id: nil)
  end

  let!(:epic_label_link1) { label_links.create!(target_type: 'Epic', target_id: epic.id, label_id: label1.id) }
  let!(:epic_label_link2) { label_links.create!(target_type: 'Epic', target_id: epic.id, label_id: label2.id) }
  let!(:invalid_label_link5) do
    label_links.create!(target_type: 'Epic', target_id: non_existing_record_id, label_id: label1.id)
  end

  let!(:invalid_label_link6) do
    label_links.create!(target_type: 'Epic', target_id: epic.id, label_id: nil)
  end

  let(:migration) do
    start_id, end_id = label_links.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :label_links,
      batch_column: :id,
      sub_batch_size: 6,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#up' do
    subject(:migrate) { migration.perform }

    it 'updates records in batches' do
      expect do
        migrate
        # 2 batches, 3 update queries per batch
      end.to make_queries_matching(/UPDATE "label_links"/, 6).and(
        make_queries_matching(/DELETE FROM "label_links"/, 2) # 2 batches, 1 delete query per batch
      )
    end

    it 'sets correct namespace_id in every record, deletes and archives orphans' do
      expect do
        migrate
      end.to change { label_links.count }.from(12).to(9).and(
        change { label_links_archived.count }.by(3)
      )

      expect(label_links.all).to contain_exactly(
        have_attributes(id: issue_label_link1.id, namespace_id: issue_namespace.id),
        have_attributes(id: issue_label_link2.id, namespace_id: issue_namespace.id),
        have_attributes(id: mr_label_link1.id, namespace_id: project_namespace.id),
        have_attributes(id: mr_label_link2.id, namespace_id: project_namespace.id),
        have_attributes(id: epic_label_link1.id, namespace_id: epic_namespace.id),
        have_attributes(id: epic_label_link2.id, namespace_id: epic_namespace.id),
        # We are not deleting invalid label links that have a nil label_id
        # as we are doing that later with another BBM
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206448#note_2784673211
        have_attributes(id: invalid_label_link2.id, namespace_id: issue_namespace.id),
        have_attributes(id: invalid_label_link4.id, namespace_id: project_namespace.id),
        have_attributes(id: invalid_label_link6.id, namespace_id: epic_namespace.id)
      )

      expect(label_links_archived.all).to contain_exactly(
        have_attributes(
          id: invalid_label_link1.id,
          target_type: 'Issue',
          target_id: non_existing_record_id,
          label_id: label1.id
        ),
        have_attributes(
          id: invalid_label_link3.id,
          target_type: 'MergeRequest',
          target_id: non_existing_record_id,
          label_id: label1.id
        ),
        have_attributes(
          id: invalid_label_link5.id,
          target_type: 'Epic',
          target_id: non_existing_record_id,
          label_id: label1.id
        )
      )
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
