require 'spec_helper'

describe Gitlab::BitbucketServerImport::Importer do
  include ImportSpecHelper

  let(:project) { create(:project, :repository, import_url: 'http://my-bitbucket') }

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

  describe '#import_pull_requests' do
    let(:sample) { RepoHelpers.sample_compare }

    before do
      allow(subject).to receive(:import_repository)
      allow(subject).to receive(:delete_temp_branches)
      allow(subject).to receive(:restore_branches)

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

      allow(subject.client).to receive(:pull_requests).and_return([pull_request])

      @merge_event = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: false,
        merge_event?: true,
        committer_email: project.owner.email,
        merge_timestamp: Time.now.utc.change(usec: 0))

      @pr_note = instance_double(
        BitbucketServer::Representation::Comment,
        note: 'Hello world',
        author_email: 'unknown@gmail.com',
        comments: [],
        created_at: Time.now.utc.change(usec: 0),
        updated_at: Time.now.utc.change(usec: 0))
      @pr_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: false,
        merge_event?: false,
        comment: @pr_note)
    end

    it 'imports merge event' do
      expect(subject.client).to receive(:activities).and_return([@merge_event])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.metrics.merged_by).to eq(project.owner)
      expect(merge_request.metrics.merged_at).to eq(@merge_event.merge_timestamp)
    end

    it 'imports comments' do
      expect(subject.client).to receive(:activities).and_return([@pr_comment])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.notes.count).to eq(1)
      note = merge_request.notes.first
      expect(note.note).to eq(@pr_note.note)
      expect(note.author).to eq(project.owner)
      expect(note.created_at).to eq(@pr_note.created_at)
      expect(note.updated_at).to eq(@pr_note.created_at)
    end

    it 'imports threaded comments' do
    end

    it 'imports diff comments' do
      # https://gitlab.com/gitlab-org/gitlab-test/compare/c1acaa58bbcbc3eafe538cb8274ba387047b69f8...5937ac0a7beb003549fc5fd26fc247ad
      inline_note = instance_double(
        BitbucketServer::Representation::PullRequestComment,
        file_type: 'ADDED',
        from_sha: sample.commits.first,
        to_sha: sample.commits.last,
        file_path: '.gitmodules',
        old_pos: nil,
        new_pos: 4,
        note: 'Hello world',
        author_email: 'unknown@gmail.com',
        comments: [],
        created_at: Time.now.utc.change(usec: 0),
        updated_at: Time.now.utc.change(usec: 0))

      inline_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: true,
        merge_event?: false,
        comment: inline_note)

      expect(subject.client).to receive(:activities).and_return([inline_comment])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.notes.count).to eq(1)
      note = merge_request.notes.first

      expect(note.type).to eq('DiffNote')
      expect(note.note).to eq(inline_note.note)
      expect(note.created_at).to eq(inline_note.created_at)
      expect(note.updated_at).to eq(inline_note.updated_at)

      expect(note.position.base_sha).to eq(inline_note.from_sha)
      expect(note.position.start_sha).to eq(inline_note.from_sha)
      expect(note.position.head_sha).to eq(inline_note.to_sha)
      expect(note.position.old_line).to be_nil
      expect(note.position.new_line).to eq(inline_note.new_pos)
    end

    it 'falls back to comments if diff comments' do
    end

    it 'restores branches of inaccessible SHAs' do
    end
  end

  describe '#delete_temp_branches' do
    it 'deletes branches' do
    end
  end
end
