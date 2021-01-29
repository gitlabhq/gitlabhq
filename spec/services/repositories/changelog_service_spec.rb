# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ChangelogService do
  describe '#execute' do
    it 'generates and commits a changelog section' do
      project = create(:project, :empty_repo)
      creator = project.creator
      author1 = create(:user)
      author2 = create(:user)

      project.add_maintainer(author1)
      project.add_maintainer(author2)

      mr1 = create(:merge_request, :merged, target_project: project)
      mr2 = create(:merge_request, :merged, target_project: project)

      # The range of commits ignores the first commit, but includes the last
      # commit. To ensure both the commits below are included, we must create an
      # extra commit.
      #
      # In the real world, the start commit of the range will be the last commit
      # of the previous release, so ignoring that is expected and desired.
      sha1 = create_commit(
        project,
        creator,
        commit_message: 'Initial commit',
        actions: [{ action: 'create', content: 'test', file_path: 'README.md' }]
      )

      sha2 = create_commit(
        project,
        author1,
        commit_message: "Title 1\n\nChangelog: feature",
        actions: [{ action: 'create', content: 'foo', file_path: 'a.txt' }]
      )

      sha3 = create_commit(
        project,
        author2,
        commit_message: "Title 2\n\nChangelog: feature",
        actions: [{ action: 'create', content: 'bar', file_path: 'b.txt' }]
      )

      commit1 = project.commit(sha2)
      commit2 = project.commit(sha3)

      allow(MergeRequestDiffCommit)
        .to receive(:oldest_merge_request_id_per_commit)
        .with(project.id, [commit2.id, commit1.id])
        .and_return([
          { sha: sha2, merge_request_id: mr1.id },
          { sha: sha3, merge_request_id: mr2.id }
        ])

      recorder = ActiveRecord::QueryRecorder.new do
        described_class
          .new(project, creator, version: '1.0.0', from: sha1, to: sha3)
          .execute
      end

      changelog = project.repository.blob_at('master', 'CHANGELOG.md')&.data

      expect(recorder.count).to eq(10)
      expect(changelog).to include('Title 1', 'Title 2')
    end
  end

  def create_commit(project, user, params)
    params = { start_branch: 'master', branch_name: 'master' }.merge(params)
    Files::MultiService.new(project, user, params).execute.fetch(:result)
  end
end
