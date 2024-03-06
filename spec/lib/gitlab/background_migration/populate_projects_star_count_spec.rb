# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateProjectsStarCount, schema: 20230616082958 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:users_star_projects) { table(:users_star_projects) }

  let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1') }
  let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2') }
  let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3') }
  let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4') }
  let(:namespace5) { namespaces.create!(name: 'namespace 5', path: 'namespace5') }

  let(:project1) { projects.create!(namespace_id: namespace1.id, project_namespace_id: namespace1.id) }
  let(:project2) { projects.create!(namespace_id: namespace2.id, project_namespace_id: namespace2.id) }
  let(:project3) { projects.create!(namespace_id: namespace3.id, project_namespace_id: namespace3.id) }
  let(:project4) { projects.create!(namespace_id: namespace4.id, project_namespace_id: namespace4.id) }
  let(:project5) { projects.create!(namespace_id: namespace5.id, project_namespace_id: namespace5.id) }

  let(:user_active) { users.create!(state: 'active', email: 'test1@example.com', projects_limit: 5) }
  let(:user_blocked) { users.create!(state: 'blocked', email: 'test2@example.com', projects_limit: 5) }

  let(:migration) do
    described_class.new(
      start_id: project1.id,
      end_id: project4.id,
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) { migration.perform }

  it 'correctly populates the star counters' do
    users_star_projects.create!(project_id: project1.id, user_id: user_active.id)
    users_star_projects.create!(project_id: project2.id, user_id: user_blocked.id)
    users_star_projects.create!(project_id: project4.id, user_id: user_active.id)
    users_star_projects.create!(project_id: project4.id, user_id: user_blocked.id)
    users_star_projects.create!(project_id: project5.id, user_id: user_active.id)

    perform_migration

    expect(project1.reload.star_count).to eq(1)
    expect(project2.reload.star_count).to eq(0)
    expect(project3.reload.star_count).to eq(0)
    expect(project4.reload.star_count).to eq(1)
    expect(project5.reload.star_count).to eq(0)
  end

  context 'when database timeouts' do
    using RSpec::Parameterized::TableSyntax

    where(error_class: [ActiveRecord::StatementTimeout, ActiveRecord::QueryCanceled])

    with_them do
      it 'retries on timeout error' do
        expect(migration).to receive(:update_batch).exactly(3).times.and_raise(error_class)
        expect(migration).to receive(:sleep).with(5).twice

        expect do
          perform_migration
        end.to raise_error(error_class)
      end
    end
  end
end
