# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateMissingDismissalInformationForVulnerabilities do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }

  let!(:vulnerability_1) { vulnerabilities.create!(title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }
  let!(:vulnerability_2) { vulnerabilities.create!(title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id, dismissed_at: Time.now) }
  let!(:vulnerability_3) { vulnerabilities.create!(title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id, dismissed_by_id: user.id) }
  let!(:vulnerability_4) { vulnerabilities.create!(title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id, dismissed_at: Time.now, dismissed_by_id: user.id) }
  let!(:vulnerability_5) { vulnerabilities.create!(title: 'title', state: 1, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules the background jobs', :aggregate_failures do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to be(3)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(3.minutes, vulnerability_1.id)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(6.minutes, vulnerability_2.id)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(9.minutes, vulnerability_3.id)
  end
end
