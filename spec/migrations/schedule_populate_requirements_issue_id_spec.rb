# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateRequirementsIssueId, feature_category: :requirements_management do
  include MigrationHelpers::WorkItemTypesHelper

  let(:issues) { table(:issues) }
  let(:requirements) { table(:requirements) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let!(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let!(:project_namespace) { namespaces.create!(name: 'project-namespace', path: 'project-namespace') }

  let!(:project) do
    projects.create!(namespace_id: group.id, project_namespace_id: project_namespace.id, name: 'gitlab', path: 'gitlab')
  end

  let(:migration) { described_class::MIGRATION }

  let!(:author) do
    users.create!(
      email: 'author@example.com',
      notification_email: 'author@example.com',
      name: 'author',
      username: 'author',
      projects_limit: 10,
      state: 'active')
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'schedules jobs for all requirements without issues in sync' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        # Restores the previous schema so we do not have a NOT NULL
        # constraint on requirements.issue_id column, which would
        # prevent us to create invalid requirement records.
        migration_context.down(previous_migration(3).version)

        requirement_1 = create_requirement(iid: 1, title: 'r 1')

        # Create one requirement with issue_id present, to make
        # sure a job won't be scheduled for it
        work_item_type_id = table(:work_item_types).find_by(namespace_id: nil, name: 'Issue').id
        issue = issues.create!(state_id: 1, work_item_type_id: work_item_type_id)
        create_requirement(iid: 2, title: 'r 2', issue_id: issue.id)

        requirement_3 = create_requirement(iid: 3, title: 'r 3')
        requirement_4 = create_requirement(iid: 4, title: 'r 4')
        requirement_5 = create_requirement(iid: 5, title: 'r 5')

        migrate!

        expect(migration).to be_scheduled_delayed_migration(120.seconds, requirement_1.id, requirement_3.id)
        expect(migration).to be_scheduled_delayed_migration(240.seconds, requirement_4.id, requirement_5.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end

  def create_requirement(iid:, title:, issue_id: nil)
    requirements.create!(
      iid: iid,
      project_id: project.id,
      issue_id: issue_id,
      title: title,
      state: 1,
      created_at: Time.now,
      updated_at: Time.now,
      author_id: author.id)
  end
end
