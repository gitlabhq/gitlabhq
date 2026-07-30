# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinaliseBackfillCommitsToPartitioned, migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:bbm) { table(:batched_background_migrations) }

  def bbm_record(table_name)
    bbm.create!(
      job_class_name: 'BackfillMergeRequestDiffCommitsToPartitioned',
      table_name: table_name,
      column_name: 'merge_request_diff_id',
      job_arguments: ['merge_request_diff_commits_b5377a7a34'],
      batch_size: 50_000,
      sub_batch_size: 1_000,
      interval: 120,
      gitlab_schema: 'gitlab_main_org',
      min_value: 1,
      max_value: 2,
      status: 3 # finished
    )
  end

  context 'when on self-managed' do
    let!(:migration) { bbm_record('merge_request_diff_commits') }

    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'finalizes the batched background migration' do
      reversible_migration do |runner|
        runner.after -> { expect(migration.reload.status).to eq(6) } # finalized
      end
    end
  end

  context 'when on GitLab.com' do
    let!(:migration) { bbm_record('merge_request_diff_commits_views_1') }

    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'finalizes the batched background migration' do
      reversible_migration do |runner|
        runner.after -> { expect(migration.reload.status).to eq(6) } # finalized
      end
    end
  end
end
