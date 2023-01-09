# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupDraftDataFromFaultyRegex, feature_category: :code_review_workflow do
  let(:merge_requests) { table(:merge_requests) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id) }

  let(:default_mr_values) do
    {
      target_project_id: project.id,
      draft: true,
      source_branch: 'master',
      target_branch: 'feature'
    }
  end

  let!(:known_good_1) { merge_requests.create!(default_mr_values.merge(title: "Draft: Test Title")) }
  let!(:known_good_2) { merge_requests.create!(default_mr_values.merge(title: "WIP: Test Title")) }
  let!(:known_bad_1) { merge_requests.create!(default_mr_values.merge(title: "Known bad title drafts")) }
  let!(:known_bad_2) { merge_requests.create!(default_mr_values.merge(title: "Known bad title wip")) }

  describe '#up' do
    it 'schedules CleanupDraftDataFromFaultyRegex background jobs filtering for eligble MRs' do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      allow(Gitlab).to receive(:com?).and_return(true)

      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, known_bad_1.id, known_bad_2.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end
end
