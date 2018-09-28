require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180425131009_assure_commits_count_for_merge_request_diff.rb')

describe AssureCommitsCountForMergeRequestDiff, :migration, :sidekiq, :redis do
  let(:migration) { spy('migration') }

  before do
    allow(Gitlab::BackgroundMigration::AddMergeRequestDiffCommitsCount)
      .to receive(:new).and_return(migration)
  end

  context 'when there are still unmigrated commit_counts afterwards' do
    let(:namespaces) { table('namespaces') }
    let(:projects) { table('projects') }
    let(:merge_requests) { table('merge_requests') }
    let(:diffs) { table('merge_request_diffs') }

    before do
      namespace = namespaces.create(name: 'foo', path: 'foo')
      project = projects.create!(namespace_id: namespace.id)
      merge_request = merge_requests.create!(source_branch: 'x', target_branch: 'y', target_project_id: project.id)
      diffs.create!(commits_count: nil, merge_request_id: merge_request.id)
      diffs.create!(commits_count: nil, merge_request_id: merge_request.id)
    end

    it 'migrates commit_counts sequentially in batches' do
      migrate!

      expect(migration).to have_received(:perform).once
    end
  end
end
