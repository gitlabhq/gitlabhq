require 'spec_helper'

describe Gitlab::BackgroundMigration::AddMergeRequestDiffCommitsCount, :migration, schema: 20180105212544 do
  let(:projects_table) { table(:projects) }
  let(:merge_requests_table) { table(:merge_requests) }
  let(:merge_request_diffs_table) { table(:merge_request_diffs) }
  let(:merge_request_diff_commits_table) { table(:merge_request_diff_commits) }

  let(:project) { projects_table.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce') }
  let(:merge_request) do
    merge_requests_table.create!(target_project_id: project.id,
                                 target_branch: 'master',
                                 source_project_id: project.id,
                                 source_branch: 'mr name',
                                 title: 'mr name')
  end

  def create_diff!(name, commits: 0)
    mr_diff = merge_request_diffs_table.create!(
      merge_request_id: merge_request.id)

    commits.times do |i|
      merge_request_diff_commits_table.create!(
        merge_request_diff_id: mr_diff.id,
        relative_order: i, sha: i)
    end

    mr_diff
  end

  describe '#perform' do
    it 'migrates diffs that have no commits' do
      diff = create_diff!('with_multiple_commits', commits: 0)

      subject.perform(diff.id, diff.id)

      expect(diff.reload.commits_count).to eq(0)
    end

    it 'skips diffs that have commits_count already set' do
      timestamp = 2.days.ago
      diff = merge_request_diffs_table.create!(
        merge_request_id: merge_request.id,
        commits_count: 0,
        updated_at: timestamp)

      subject.perform(diff.id, diff.id)

      expect(diff.reload.updated_at).to be_within(1.second).of(timestamp)
    end

    it 'migrates multiple diffs to the correct values' do
      diffs = Array.new(3).map.with_index { |_, i| create_diff!(i, commits: 3) }

      subject.perform(diffs.first.id, diffs.last.id)

      diffs.each do |diff|
        expect(diff.reload.commits_count).to eq(3)
      end
    end
  end
end
