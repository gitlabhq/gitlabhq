# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ScheduleBackfillDraftStatusOnMergeRequests, :sidekiq do
  let(:namespaces)     { table(:namespaces) }
  let(:projects)       { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }

  let(:group)   { namespaces.create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { projects.create!(namespace_id: group.id) }

  let(:draft_prefixes) { ["[Draft]", "(Draft)", "Draft:", "Draft", "[WIP]", "WIP:", "WIP"] }

  def create_merge_request(params)
    common_params = {
      target_project_id: project.id,
      target_branch: 'feature1',
      source_branch: 'master'
    }

    merge_requests.create!(common_params.merge(params))
  end

  before do
    draft_prefixes.each do |prefix|
      (1..4).each do |n|
        create_merge_request(
          title: "#{prefix} This is a title",
          draft: false,
          state_id: n
        )
      end
    end

    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'schedules BackfillDraftStatusOnMergeRequests background jobs' do
    Sidekiq::Testing.fake! do
      draft_mrs = Gitlab::BackgroundMigration::BackfillDraftStatusOnMergeRequests::MergeRequest.eligible

      first_mr_id = draft_mrs.first.id
      second_mr_id = draft_mrs.second.id

      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(7)
        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, first_mr_id, first_mr_id)
        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, second_mr_id, second_mr_id)
      end
    end
  end
end
