# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20211004110500_add_temporary_index_to_issue_metrics.rb')

RSpec.describe Gitlab::BackgroundMigration::FixFirstMentionedInCommitAt, :migration, schema: 20211004110500 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:issue_metrics) { table(:issue_metrics) }
  let(:merge_requests_closing_issues) { table(:merge_requests_closing_issues) }
  let(:diffs) { table(:merge_request_diffs) }
  let(:ten_days_ago) { 10.days.ago }
  let(:commits) do
    table(:merge_request_diff_commits).tap do |t|
      t.extend(SuppressCompositePrimaryKeyWarning)
    end
  end

  let(:namespace) { namespaces.create!(name: 'ns', path: 'ns') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  let!(:issue1) do
    issues.create!(
      title: 'issue',
      description: 'description',
      project_id: project.id
    )
  end

  let!(:issue2) do
    issues.create!(
      title: 'issue',
      description: 'description',
      project_id: project.id
    )
  end

  let!(:merge_request1) do
    merge_requests.create!(
      source_branch: 'a',
      target_branch: 'master',
      target_project_id: project.id
    )
  end

  let!(:merge_request2) do
    merge_requests.create!(
      source_branch: 'b',
      target_branch: 'master',
      target_project_id: project.id
    )
  end

  let!(:merge_request_closing_issue1) do
    merge_requests_closing_issues.create!(issue_id: issue1.id, merge_request_id: merge_request1.id)
  end

  let!(:merge_request_closing_issue2) do
    merge_requests_closing_issues.create!(issue_id: issue2.id, merge_request_id: merge_request2.id)
  end

  let!(:diff1) { diffs.create!(merge_request_id: merge_request1.id) }
  let!(:diff2) { diffs.create!(merge_request_id: merge_request1.id) }

  let!(:other_diff) { diffs.create!(merge_request_id: merge_request2.id) }

  let!(:commit1) do
    commits.create!(
      merge_request_diff_id: diff2.id,
      relative_order: 0,
      sha: Gitlab::Database::ShaAttribute.serialize('aaa'),
      authored_date: 5.days.ago
    )
  end

  let!(:commit2) do
    commits.create!(
      merge_request_diff_id: diff2.id,
      relative_order: 1,
      sha: Gitlab::Database::ShaAttribute.serialize('aaa'),
      authored_date: 10.days.ago
    )
  end

  let!(:commit3) do
    commits.create!(
      merge_request_diff_id: other_diff.id,
      relative_order: 1,
      sha: Gitlab::Database::ShaAttribute.serialize('aaa'),
      authored_date: 5.days.ago
    )
  end

  def run_migration
    described_class
      .new
      .perform(issue_metrics.minimum(:issue_id), issue_metrics.maximum(:issue_id))
  end

  shared_examples 'fixes first_mentioned_in_commit_at' do
    it "marks successful slices as completed" do
      min_issue_id = issue_metrics.minimum(:issue_id)
      max_issue_id = issue_metrics.maximum(:issue_id)

      expect(subject).to receive(:mark_job_as_succeeded).with(min_issue_id, max_issue_id)

      subject.perform(min_issue_id, max_issue_id)
    end

    context 'when the persisted first_mentioned_in_commit_at is later than the first commit authored_date' do
      it 'updates the issue_metrics record' do
        record1 = issue_metrics.create!(issue_id: issue1.id, first_mentioned_in_commit_at: Time.current)
        record2 = issue_metrics.create!(issue_id: issue2.id, first_mentioned_in_commit_at: Time.current)

        run_migration
        record1.reload
        record2.reload

        expect(record1.first_mentioned_in_commit_at).to be_within(2.seconds).of(commit2.authored_date)
        expect(record2.first_mentioned_in_commit_at).to be_within(2.seconds).of(commit3.authored_date)
      end
    end

    context 'when the persisted first_mentioned_in_commit_at is earlier than the first commit authored_date' do
      it 'does not update the issue_metrics record' do
        record = issue_metrics.create!(issue_id: issue1.id, first_mentioned_in_commit_at: 20.days.ago)

        expect { run_migration }.not_to change { record.reload.first_mentioned_in_commit_at }
      end
    end

    context 'when the first_mentioned_in_commit_at is null' do
      it 'does nothing' do
        record = issue_metrics.create!(issue_id: issue1.id, first_mentioned_in_commit_at: nil)

        expect { run_migration }.not_to change { record.reload.first_mentioned_in_commit_at }
      end
    end
  end

  describe 'running the migration when first_mentioned_in_commit_at is timestamp without time zone' do
    it_behaves_like 'fixes first_mentioned_in_commit_at'
  end

  describe 'running the migration when first_mentioned_in_commit_at is timestamp with time zone' do
    around do |example|
      AddTemporaryIndexToIssueMetrics.new.down

      ActiveRecord::Base.connection.execute "ALTER TABLE issue_metrics ALTER first_mentioned_in_commit_at type timestamp with time zone"
      Gitlab::BackgroundMigration::FixFirstMentionedInCommitAt::TmpIssueMetrics.reset_column_information
      AddTemporaryIndexToIssueMetrics.new.up

      example.run

      AddTemporaryIndexToIssueMetrics.new.down
      ActiveRecord::Base.connection.execute "ALTER TABLE issue_metrics ALTER first_mentioned_in_commit_at type timestamp without time zone"
      Gitlab::BackgroundMigration::FixFirstMentionedInCommitAt::TmpIssueMetrics.reset_column_information
      AddTemporaryIndexToIssueMetrics.new.up
    end

    it_behaves_like 'fixes first_mentioned_in_commit_at'
  end
end
