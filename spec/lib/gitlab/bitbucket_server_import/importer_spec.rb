require 'spec_helper'

describe Gitlab::BitbucketServerImport::Importer do
  include ImportSpecHelper

  set(:project) { create(:project, :repository, import_url: 'http://my-bitbucket') }

  subject { described_class.new(project) }

  before do
    data = project.create_or_update_import_data(
      data: { project_key: 'TEST', repo_slug: 'rouge' },
      credentials: { base_uri: 'http://my-bitbucket', user: 'bitbucket', password: 'test' }
    )
    data.save
    project.save
  end

  describe '#import_repository' do
    before do
      expect(subject).to receive(:import_pull_requests)
      expect(subject).to receive(:delete_temp_branches)
    end

    it 'adds a remote' do
      expect(project.repository).to receive(:fetch_as_mirror)
                                     .with('http://bitbucket:test@my-bitbucket',
                                           refmap: [:heads, :tags, '+refs/pull-requests/*/to:refs/merge-requests/*/head'],
                                           remote_name: 'bitbucket_server')

      subject.execute
    end
  end

  # XXX We don't handle pull requests across forks
  describe '#import_pull_requests' do
    before do
      allow(subject).to receive(:import_repository)
      allow(subject).to receive(:delete_temp_branches)
      allow(subject).to receive(:restore_branches)

      sample = RepoHelpers.sample_compare
      pull_request = instance_double(
        BitbucketServer::Representation::PullRequest,
        iid: 10,
        source_branch_sha: sample.commits.last,
        source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
        target_branch_sha: sample.commits.first,
        target_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.target_branch,
        title: 'This is a title',
        description: 'This is a test pull request',
        state: 'merged',
        author: 'Test Author',
        author_email: project.owner.email,
        created_at: Time.now,
        updated_at: Time.now,
        merged?: true)

      expect(subject.client).to receive(:pull_requests).and_return([pull_request])

      @merge_event = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: false,
        merge_event?: true,
        committer_email: project.owner.email,
        merge_timestamp: Time.now)
      @inline_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        merge_event?: false)
      @pr_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        merge_event?: false)
    end

    it 'handles merge event' do
      expect(subject.client).to receive(:activities).and_return([@merge_event])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.metrics.merged_by).to eq(project.owner)
      expect(merge_request.metrics.merged_at).to eq(@merge_event.merge_timestamp)
    end

    context 'handles comments' do
    end

    context 'handles diff comments' do
    end

    context 'falls back to comments if diff comments' do
    end

    context 'restores branches of inaccessible SHAs' do
    end
  end

  describe '#delete_temp_branches' do
  end
end
