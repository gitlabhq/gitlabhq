require 'spec_helper'

describe Gitlab::BitbucketServerImport::Importer do
  include ImportSpecHelper

  let(:project) { create(:project, :repository, import_url: 'http://my-bitbucket') }
  let(:now) { Time.now.utc.change(usec: 0) }
  let(:project_key) { 'TEST' }
  let(:repo_slug) { 'rouge' }
  let(:sample) { RepoHelpers.sample_compare }

  subject { described_class.new(project, recover_missing_commits: true) }

  before do
    data = project.create_or_update_import_data(
      data: { project_key: project_key, repo_slug: repo_slug },
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
        merge_timestamp: now,
        merge_commit: '12345678'
      )

      @pr_note = instance_double(
        BitbucketServer::Representation::Comment,
        note: 'Hello world',
        author_email: 'unknown@gmail.com',
        comments: [],
        created_at: now,
        updated_at: now,
        parent_comment: nil)

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
      expect(merge_request.merge_commit_sha).to eq('12345678')
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

    it 'imports threaded discussions' do
      reply = instance_double(
        BitbucketServer::Representation::PullRequestComment,
        author_email: 'someuser@gitlab.com',
        note: 'I agree',
        created_at: now,
        updated_at: now)

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
        comments: [reply],
        created_at: now,
        updated_at: now,
        parent_comment: nil)

      allow(reply).to receive(:parent_comment).and_return(inline_note)

      inline_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: true,
        merge_event?: false,
        comment: inline_note)

      expect(subject.client).to receive(:activities).and_return([inline_comment])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.notes.count).to eq(2)
      expect(merge_request.notes.map(&:discussion_id).uniq.count).to eq(1)

      notes = merge_request.notes.order(:id).to_a
      start_note = notes.first
      expect(start_note.type).to eq('DiffNote')
      expect(start_note.note).to eq(inline_note.note)
      expect(start_note.created_at).to eq(inline_note.created_at)
      expect(start_note.updated_at).to eq(inline_note.updated_at)
      expect(start_note.position.base_sha).to eq(inline_note.from_sha)
      expect(start_note.position.start_sha).to eq(inline_note.from_sha)
      expect(start_note.position.head_sha).to eq(inline_note.to_sha)
      expect(start_note.position.old_line).to be_nil
      expect(start_note.position.new_line).to eq(inline_note.new_pos)

      reply_note = notes.last
      # Make sure reply context is included
      expect(reply_note.note).to eq("> #{inline_note.note}\n\n#{reply.note}")
      expect(reply_note.author).to eq(project.owner)
      expect(reply_note.created_at).to eq(reply.created_at)
      expect(reply_note.updated_at).to eq(reply.created_at)
      expect(reply_note.position.base_sha).to eq(inline_note.from_sha)
      expect(reply_note.position.start_sha).to eq(inline_note.from_sha)
      expect(reply_note.position.head_sha).to eq(inline_note.to_sha)
      expect(reply_note.position.old_line).to be_nil
      expect(reply_note.position.new_line).to eq(inline_note.new_pos)
    end

    it 'falls back to comments if diff comments fail to validate' do
      reply = instance_double(
        BitbucketServer::Representation::Comment,
        author_email: 'someuser@gitlab.com',
        note: 'I agree',
        created_at: now,
        updated_at: now)

      # https://gitlab.com/gitlab-org/gitlab-test/compare/c1acaa58bbcbc3eafe538cb8274ba387047b69f8...5937ac0a7beb003549fc5fd26fc247ad
      inline_note = instance_double(
        BitbucketServer::Representation::PullRequestComment,
        file_type: 'REMOVED',
        from_sha: sample.commits.first,
        to_sha: sample.commits.last,
        file_path: '.gitmodules',
        old_pos: 8,
        new_pos: 9,
        note: 'This is a note with an invalid line position.',
        author_email: project.owner.email,
        comments: [reply],
        created_at: now,
        updated_at: now,
        parent_comment: nil)

      inline_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: true,
        merge_event?: false,
        comment: inline_note)

      allow(reply).to receive(:parent_comment).and_return(inline_note)

      expect(subject.client).to receive(:activities).and_return([inline_comment])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.notes.count).to eq(2)
      notes = merge_request.notes

      expect(notes.first.note).to start_with('*Comment on .gitmodules')
      expect(notes.second.note).to start_with('*Comment on .gitmodules')
    end
  end

  describe 'inaccessible branches' do
    let(:id) { 10 }
    let(:temp_branch_from) { "gitlab/import/pull-request/#{id}/from" }
    let(:temp_branch_to) { "gitlab/import/pull-request/#{id}/to" }

    before do
      pull_request = instance_double(
        BitbucketServer::Representation::PullRequest,
        iid: id,
        source_branch_sha: '12345678',
        source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
        target_branch_sha: '98765432',
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
      expect(subject.client).to receive(:activities).and_return([])
      expect(subject).to receive(:import_repository).twice
    end

    it '#restore_branches' do
      expect(subject).to receive(:restore_branches).and_call_original
      expect(subject).to receive(:delete_temp_branches)
      expect(subject.client).to receive(:create_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_from,
                                       '12345678')
      expect(subject.client).to receive(:create_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_to,
                                       '98765432')

      expect { subject.execute }.to change { MergeRequest.count }.by(1)
    end

    it '#delete_temp_branches' do
      expect(subject.client).to receive(:create_branch).twice
      expect(subject).to receive(:delete_temp_branches).and_call_original
      expect(subject.client).to receive(:delete_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_from,
                                       '12345678')
      expect(subject.client).to receive(:delete_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_to,
                                       '98765432')
      expect(project.repository).to receive(:delete_branch).with(temp_branch_from)
      expect(project.repository).to receive(:delete_branch).with(temp_branch_to)

      expect { subject.execute }.to change { MergeRequest.count }.by(1)
    end
  end
end
