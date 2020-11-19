# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateHasVulnerabilities do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:vulnerability_base_params) { { title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, author_id: user.id } }
  let!(:project_1) { projects.create!(namespace_id: namespace.id, name: 'foo_1') }
  let!(:project_2) { projects.create!(namespace_id: namespace.id, name: 'foo_2') }
  let!(:project_3) { projects.create!(namespace_id: namespace.id, name: 'foo_3') }

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    vulnerabilities.create!(vulnerability_base_params.merge(project_id: project_1.id))
    vulnerabilities.create!(vulnerability_base_params.merge(project_id: project_3.id))
  end

  it 'schedules the background jobs', :aggregate_failures do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to be(2)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(2.minutes, project_1.id)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(4.minutes, project_3.id)
  end
end
