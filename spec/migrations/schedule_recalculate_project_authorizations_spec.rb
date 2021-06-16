# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleRecalculateProjectAuthorizations do
  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_authorizations_table) { table(:project_authorizations) }

  let(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 1) }
  let(:user2) { users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 1) }
  let(:group) { namespaces_table.create!(id: 1, type: 'Group', name: 'group', path: 'group') }
  let(:project) do
    projects_table.create!(id: 1, name: 'project', path: 'project',
                           visibility_level: 0, namespace_id: group.id)
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)

    project_authorizations_table.create!(user_id: user1.id, project_id: project.id, access_level: 30)
    project_authorizations_table.create!(user_id: user2.id, project_id: project.id, access_level: 30)
  end

  it 'schedules background migration' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(described_class::MIGRATION).to be_scheduled_migration([user1.id])
        expect(described_class::MIGRATION).to be_scheduled_migration([user2.id])
      end
    end
  end

  it 'ignores projects with higher id than maximum group id' do
    another_user = users_table.create!(name: 'another user', email: 'another-user@example.com',
                                       projects_limit: 1)
    ignored_project = projects_table.create!(id: 2, name: 'ignored-project', path: 'ignored-project',
                                             visibility_level: 0, namespace_id: group.id)
    project_authorizations_table.create!(user_id: another_user.id, project_id: ignored_project.id,
                                         access_level: 30)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(described_class::MIGRATION).to be_scheduled_migration([user1.id])
        expect(described_class::MIGRATION).to be_scheduled_migration([user2.id])
      end
    end
  end
end
