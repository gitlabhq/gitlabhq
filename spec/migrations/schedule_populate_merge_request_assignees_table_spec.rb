# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateMergeRequestAssigneesTable do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }

  def create_merge_request(id)
    params = {
      id: id,
      target_project_id: project.id,
      target_branch: 'master',
      source_project_id: project.id,
      source_branch: 'mr name',
      title: "mr name#{id}"
    }

    merge_requests.create!(params)
  end

  it 'correctly schedules background migrations' do
    create_merge_request(1)
    create_merge_request(2)
    create_merge_request(3)

    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(8.minutes, 1, 2)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(16.minutes, 3, 3)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
