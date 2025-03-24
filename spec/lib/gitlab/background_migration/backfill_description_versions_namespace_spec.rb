# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDescriptionVersionsNamespace,
  :migration_with_transaction,
  feature_category: :team_planning do
  let(:description_versions) { table(:description_versions) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:project_namespace) do
    table(:namespaces).create!(name: "project1", path: "project1", organization_id: organization.id)
  end

  let(:issue_namespace) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:epic_namespace) do
    table(:namespaces).create!(name: "group1", path: "group1", organization_id: organization.id)
  end

  let(:fake_namespace) do
    # Can't create description_versions without a namespace in specs due to the invalid FK
    table(:namespaces).create!(id: 0, name: "fake", path: "fake", organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(
      namespace_id: project_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let(:merge_request) do
    table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'not-main')
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

  let(:user) { table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 2) }
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

  let!(:issue_description1) do
    description_versions.create!(
      issue_id: issue.id,
      description: 'desc1',
      namespace_id: fake_namespace.id
    )
  end

  let!(:issue_description2) do
    description_versions.create!(
      issue_id: issue.id,
      description: 'desc2',
      namespace_id: fake_namespace.id
    )
  end

  let!(:mr_description1) do
    description_versions.create!(
      merge_request_id: merge_request.id,
      description: 'desc1',
      namespace_id: fake_namespace.id
    )
  end

  let!(:mr_description2) do
    description_versions.create!(
      merge_request_id: merge_request.id,
      description: 'desc2',
      namespace_id: fake_namespace.id
    )
  end

  let!(:epic_description1) do
    description_versions.create!(
      epic_id: epic.id,
      description: 'desc1',
      namespace_id: fake_namespace.id
    )
  end

  let!(:epic_description2) do
    description_versions.create!(
      epic_id: epic.id,
      description: 'desc2',
      namespace_id: fake_namespace.id
    )
  end

  let(:migration) do
    start_id, end_id = description_versions.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :description_versions,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  subject(:migrate) { migration.perform }

  describe '#up' do
    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/UPDATE\s+"description_versions"/, 9) # 3 updates per batch
    end

    it 'sets correct namespace_id in every record' do
      expect { migrate }.to change { issue_description1.reload.namespace_id }.from(0).to(issue_namespace.id).and(
        change { issue_description2.reload.namespace_id }.from(0).to(issue_namespace.id)
      ).and(
        change { mr_description1.reload.namespace_id }.from(0).to(project_namespace.id)
      ).and(
        change { mr_description2.reload.namespace_id }.from(0).to(project_namespace.id)
      ).and(
        change { epic_description1.reload.namespace_id }.from(0).to(epic_namespace.id)
      ).and(
        change { epic_description2.reload.namespace_id }.from(0).to(epic_namespace.id)
      )
    end

    # We don't expect invalid records to exist. Just a safety measure.
    context 'when there are invalid records' do
      before do
        # No other way to create invalid records for the spec. Entire spec file runs in transaction.
        description_versions.connection.execute(
          'ALTER TABLE description_versions DROP CONSTRAINT IF EXISTS check_76c1eb7122'
        )

        # Records with more than 1 parent
        description_versions.create!(
          description: 'invalid', namespace_id: fake_namespace.id, issue_id: issue.id, epic_id: epic.id
        )
        description_versions.create!(
          description: 'invalid',
          namespace_id: fake_namespace.id,
          issue_id: issue.id,
          merge_request_id: merge_request.id
        )
        description_versions.create!(
          description: 'invalid',
          namespace_id: fake_namespace.id,
          merge_request_id: merge_request.id,
          epic_id: epic.id,
          issue_id: issue.id
        )
        # Records with no parent
        description_versions.create!(description: 'invalid description', namespace_id: fake_namespace.id)
      end

      it 'deletes invalid records', :aggregate_failures do
        expect { migrate }.to change { description_versions.count }.from(10).to(6)

        expect(description_versions.pluck(:id)).to match_array(
          [
            issue_description1,
            issue_description2,
            mr_description1,
            mr_description2,
            epic_description1,
            epic_description2
          ].map(&:id)
        )
      end
    end
  end
end
