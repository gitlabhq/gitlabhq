# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnqueueResetMergeStatus do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:merge_requests) { table(:merge_requests) }

  def create_merge_request(id, extra_params = {})
    params = {
      id: id,
      target_project_id: project.id,
      target_branch: 'master',
      source_project_id: project.id,
      source_branch: 'mr name',
      title: "mr name#{id}"
    }.merge(extra_params)

    merge_requests.create!(params)
  end

  it 'correctly schedules background migrations' do
    create_merge_request(1, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(2, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(3, state: 'opened', merge_status: 'can_be_merged')
    create_merge_request(4, state: 'merged', merge_status: 'can_be_merged')
    create_merge_request(5, state: 'opened', merge_status: 'unchecked')

    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(5.minutes, 1, 2)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(10.minutes, 3, 4)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(15.minutes, 5, 5)

        expect(BackgroundMigrationWorker.jobs.size).to eq(3)
      end
    end
  end
end
