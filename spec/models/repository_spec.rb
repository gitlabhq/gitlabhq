require 'spec_helper'

describe Repository do
  include RepoHelpers
  TestBlob = Struct.new(:path)

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:broken_repository) { create(:project, :broken_storage).repository }
  let(:user) { create(:user) }
  let(:git_user) { Gitlab::Git::User.from_gitlab(user) }

  let(:message) { 'Test message' }

  let(:merge_commit) do
    merge_request = create(:merge_request, source_branch: 'feature', target_branch: 'master', source_project: project)

    merge_commit_id = repository.merge(user,
                                       merge_request.diff_head_sha,
                                       merge_request,
                                       message)

    repository.commit(merge_commit_id)
  end

  let(:author_email) { 'user@example.org' }
  let(:author_name) { 'John Doe' }

  def expect_to_raise_storage_error
    expect { yield }.to raise_error do |exception|
      storage_exceptions = [Gitlab::Git::Storage::Inaccessible, Gitlab::Git::CommandError, GRPC::Unavailable]
      known_exception = storage_exceptions.select { |e| exception.is_a?(e) }

      expect(known_exception).not_to be_nil
    end
  end

  describe '#branch_names_contains' do
    shared_examples '#branch_names_contains' do
      set(:project) { create(:project, :repository) }
      let(:repository) { project.repository }

      subject { repository.branch_names_contains(sample_commit.id) }

      it { is_expected.to include('master') }
      it { is_expected.not_to include('feature') }
      it { is_expected.not_to include('fix') }

      describe 'when storage is broken', :broken_storage  do
        it 'should raise a storage error' do
          expect_to_raise_storage_error do
            broken_repository.branch_names_contains(sample_commit.id)
          end
        end
      end
    end

    context 'when gitaly is enabled' do
      it_behaves_like '#branch_names_contains'
    end

    context 'when gitaly is disabled', :skip_gitaly_mock do
      it_behaves_like '#branch_names_contains'
    end
  end

  describe '#tag_names_contains' do
    shared_examples '#tag_names_contains' do
      subject { repository.tag_names_contains(sample_commit.id) }

      it { is_expected.to include('v1.1.0') }
      it { is_expected.not_to include('v1.0.0') }
    end

    context 'when gitaly is enabled' do
      it_behaves_like '#tag_names_contains'
    end

    context 'when gitaly is enabled', :skip_gitaly_mock do
      it_behaves_like '#tag_names_contains'
    end
  end

  describe 'tags_sorted_by' do
    context 'name_desc' do
      subject { repository.tags_sorted_by('name_desc').map(&:name) }

      it { is_expected.to eq(['v1.1.0', 'v1.0.0']) }
    end

    context 'name_asc' do
      subject { repository.tags_sorted_by('name_asc').map(&:name) }

      it { is_expected.to eq(['v1.0.0', 'v1.1.0']) }
    end

    context 'updated' do
      let(:tag_a) { repository.find_tag('v1.0.0') }
      let(:tag_b) { repository.find_tag('v1.1.0') }

      context 'desc' do
        subject { repository.tags_sorted_by('updated_desc').map(&:name) }

        before do
          double_first = double(committed_date: Time.now)
          double_last = double(committed_date: Time.now - 1.second)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_first)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_last)
          allow(repository).to receive(:tags).and_return([tag_a, tag_b])
        end

        it { is_expected.to eq(['v1.0.0', 'v1.1.0']) }
      end

      context 'asc' do
        subject { repository.tags_sorted_by('updated_asc').map(&:name) }

        before do
          double_first = double(committed_date: Time.now - 1.second)
          double_last = double(committed_date: Time.now)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_last)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_first)
          allow(repository).to receive(:tags).and_return([tag_a, tag_b])
        end

        it { is_expected.to eq(['v1.1.0', 'v1.0.0']) }
      end

      context 'annotated tag pointing to a blob' do
        let(:annotated_tag_name) { 'annotated-tag' }

        subject { repository.tags_sorted_by('updated_asc').map(&:name) }

        before do
          options = { message: 'test tag message\n',
                      tagger: { name: 'John Smith', email: 'john@gmail.com' } }
          repository.rugged.tags.create(annotated_tag_name, 'a48e4fc218069f68ef2e769dd8dfea3991362175', options)

          double_first = double(committed_date: Time.now - 1.second)
          double_last = double(committed_date: Time.now)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_last)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_first)
        end

        it { is_expected.to eq(['v1.1.0', 'v1.0.0', annotated_tag_name]) }

        after do
          repository.rugged.tags.delete(annotated_tag_name)
        end
      end
    end
  end

  describe '#ref_name_for_sha' do
    it 'returns the ref' do
      allow(repository.raw_repository).to receive(:ref_name_for_sha)
        .and_return('refs/environments/production/77')

      expect(repository.ref_name_for_sha('bla', '0' * 40)).to eq 'refs/environments/production/77'
    end
  end

  describe '#ref_exists?' do
    context 'when ref exists' do
      it 'returns true' do
        expect(repository.ref_exists?('refs/heads/master')).to be true
      end
    end

    context 'when ref does not exist' do
      it 'returns false' do
        expect(repository.ref_exists?('refs/heads/non-existent')).to be false
      end
    end

    context 'when ref format is incorrect' do
      it 'returns false' do
        expect(repository.ref_exists?('refs/heads/invalid:master')).to be false
      end
    end
  end

  describe '#last_commit_for_path' do
    shared_examples 'getting last commit for path' do
      subject { repository.last_commit_for_path(sample_commit.id, '.gitignore').id }

      it { is_expected.to eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8') }

      describe 'when storage is broken', :broken_storage  do
        it 'should raise a storage error' do
          expect_to_raise_storage_error do
            broken_repository.last_commit_id_for_path(sample_commit.id, '.gitignore')
          end
        end
      end
    end

    context 'when Gitaly feature last_commit_for_path is enabled' do
      it_behaves_like 'getting last commit for path'
    end

    context 'when Gitaly feature last_commit_for_path is disabled', :skip_gitaly_mock do
      it_behaves_like 'getting last commit for path'
    end
  end

  describe '#last_commit_id_for_path' do
    shared_examples 'getting last commit ID for path' do
      subject { repository.last_commit_id_for_path(sample_commit.id, '.gitignore') }

      it "returns last commit id for a given path" do
        is_expected.to eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8')
      end

      it "caches last commit id for a given path" do
        cache = repository.send(:cache)
        key = "last_commit_id_for_path:#{sample_commit.id}:#{Digest::SHA1.hexdigest('.gitignore')}"

        expect(cache).to receive(:fetch).with(key).and_return('c1acaa5')
        is_expected.to eq('c1acaa5')
      end

      describe 'when storage is broken', :broken_storage  do
        it 'should raise a storage error' do
          expect_to_raise_storage_error do
            broken_repository.last_commit_for_path(sample_commit.id, '.gitignore').id
          end
        end
      end
    end

    context 'when Gitaly feature last_commit_for_path is enabled' do
      it_behaves_like 'getting last commit ID for path'
    end

    context 'when Gitaly feature last_commit_for_path is disabled', :skip_gitaly_mock do
      it_behaves_like 'getting last commit ID for path'
    end
  end

  describe '#commits' do
    context 'when neither the all flag nor a ref are specified' do
      it 'returns every commit from default branch' do
        expect(repository.commits(limit: 60).size).to eq(37)
      end
    end

    context 'when ref is passed' do
      it 'returns every commit from the specified ref' do
        expect(repository.commits('master', limit: 60).size).to eq(37)
      end

      context 'when all' do
        it 'returns every commit from the repository' do
          expect(repository.commits('master', limit: 60, all: true).size).to eq(60)
        end
      end

      context 'with path' do
        it 'sets follow when it is a single path' do
          expect(Gitlab::Git::Commit).to receive(:where).with(a_hash_including(follow: true)).and_call_original.twice

          repository.commits('master', limit: 1, path: 'README.md')
          repository.commits('master', limit: 1, path: ['README.md'])
        end

        it 'does not set follow when it is multiple paths' do
          expect(Gitlab::Git::Commit).to receive(:where).with(a_hash_including(follow: false)).and_call_original

          repository.commits('master', limit: 1, path: ['README.md', 'CHANGELOG'])
        end
      end

      context 'without path' do
        it 'does not set follow' do
          expect(Gitlab::Git::Commit).to receive(:where).with(a_hash_including(follow: false)).and_call_original

          repository.commits('master', limit: 1)
        end
      end
    end

    context "when 'all' flag is set" do
      it 'returns every commit from the repository' do
        expect(repository.commits(all: true, limit: 60).size).to eq(60)
      end
    end
  end

  describe '#new_commits' do
    let(:new_refs) do
      double(:git_rev_list, new_refs: %w[
        c1acaa58bbcbc3eafe538cb8274ba387047b69f8
        5937ac0a7beb003549fc5fd26fc247adbce4a52e
      ])
    end

    it 'delegates to Gitlab::Git::RevList' do
      expect(Gitlab::Git::RevList).to receive(:new).with(
        repository.raw,
        newrev: 'aaaabbbbccccddddeeeeffffgggghhhhiiiijjjj').and_return(new_refs)

      commits = repository.new_commits('aaaabbbbccccddddeeeeffffgggghhhhiiiijjjj')

      expect(commits).to eq([
        repository.commit('c1acaa58bbcbc3eafe538cb8274ba387047b69f8'),
        repository.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      ])
    end
  end

  describe '#commits_by' do
    set(:project) { create(:project, :repository) }

    shared_examples 'batch commits fetching' do
      let(:oids) { TestEnv::BRANCH_SHA.values }

      subject { project.repository.commits_by(oids: oids) }

      it 'finds each commit' do
        expect(subject).not_to include(nil)
        expect(subject.size).to eq(oids.size)
      end

      it 'returns only Commit instances' do
        expect(subject).to all( be_a(Commit) )
      end

      context 'when some commits are not found ' do
        let(:oids) do
          ['deadbeef'] + TestEnv::BRANCH_SHA.values.first(10)
        end

        it 'returns only found commits' do
          expect(subject).not_to include(nil)
          expect(subject.size).to eq(10)
        end
      end

      context 'when no oids are passed' do
        let(:oids) { [] }

        it 'does not call #batch_by_oid' do
          expect(Gitlab::Git::Commit).not_to receive(:batch_by_oid)

          subject
        end
      end
    end

    context 'when Gitaly list_commits_by_oid is enabled' do
      it_behaves_like 'batch commits fetching'
    end

    context 'when Gitaly list_commits_by_oid is enabled', :disable_gitaly do
      it_behaves_like 'batch commits fetching'
    end
  end

  describe '#find_commits_by_message' do
    shared_examples 'finding commits by message' do
      it 'returns commits with messages containing a given string' do
        commit_ids = repository.find_commits_by_message('submodule').map(&:id)

        expect(commit_ids).to include(
          '5937ac0a7beb003549fc5fd26fc247adbce4a52e',
          '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
          'cfe32cf61b73a0d5e9f13e774abde7ff789b1660'
        )
        expect(commit_ids).not_to include('913c66a37b4a45b9769037c55c2d238bd0942d2e')
      end

      it 'is case insensitive' do
        commit_ids = repository.find_commits_by_message('SUBMODULE').map(&:id)

        expect(commit_ids).to include('5937ac0a7beb003549fc5fd26fc247adbce4a52e')
      end
    end

    context 'when Gitaly commits_by_message feature is enabled' do
      it_behaves_like 'finding commits by message'
    end

    context 'when Gitaly commits_by_message feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding commits by message'
    end

    describe 'when storage is broken', :broken_storage do
      it 'should raise a storage error' do
        expect_to_raise_storage_error { broken_repository.find_commits_by_message('s') }
      end
    end
  end

  describe '#blob_at' do
    context 'blank sha' do
      subject { repository.blob_at(Gitlab::Git::BLANK_SHA, '.gitignore') }

      it { is_expected.to be_nil }
    end
  end

  describe '#merged_to_root_ref?' do
    context 'merged branch without ff' do
      subject { repository.merged_to_root_ref?('branch-merged') }

      it { is_expected.to be_truthy }
    end

    # If the HEAD was ff then it will be false
    context 'merged with ff' do
      subject { repository.merged_to_root_ref?('improve/awesome') }

      it { is_expected.to be_truthy }
    end

    context 'not merged branch' do
      subject { repository.merged_to_root_ref?('not-merged-branch') }

      it { is_expected.to be_falsey }
    end

    context 'default branch' do
      subject { repository.merged_to_root_ref?('master') }

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_be_merged?' do
    shared_examples 'can be merged' do
      context 'mergeable branches' do
        subject { repository.can_be_merged?('0b4bc9a49b562e85de7cc9e834518ea6828729b9', 'master') }

        it { is_expected.to be_truthy }
      end

      context 'non-mergeable branches without conflict sides missing' do
        subject { repository.can_be_merged?('bb5206fee213d983da88c47f9cf4cc6caf9c66dc', 'feature') }

        it { is_expected.to be_falsey }
      end

      context 'non-mergeable branches with conflict sides missing' do
        subject { repository.can_be_merged?('conflict-missing-side', 'conflict-start') }

        it { is_expected.to be_falsey }
      end

      context 'non merged branch' do
        subject { repository.merged_to_root_ref?('fix') }

        it { is_expected.to be_falsey }
      end

      context 'non existent branch' do
        subject { repository.merged_to_root_ref?('non_existent_branch') }

        it { is_expected.to be_nil }
      end
    end

    context 'when Gitaly can_be_merged feature is enabled' do
      it_behaves_like 'can be merged'
    end

    context 'when Gitaly can_be_merged feature is disabled', :disable_gitaly do
      it_behaves_like 'can be merged'
    end
  end

  describe '#commit' do
    context 'when ref exists' do
      it 'returns commit object' do
        expect(repository.commit('master'))
          .to be_an_instance_of Commit
      end
    end

    context 'when ref does not exist' do
      it 'returns nil' do
        expect(repository.commit('non-existent-ref')).to be_nil
      end
    end

    context 'when ref is not valid' do
      context 'when preceding tree element exists' do
        it 'returns nil' do
          expect(repository.commit('master:ref')).to be_nil
        end
      end

      context 'when preceding tree element does not exist' do
        it 'returns nil' do
          expect(repository.commit('non-existent:ref')).to be_nil
        end
      end
    end
  end

  describe '#create_hooks' do
    let(:hook_path) { File.join(repository.path_to_repo, 'hooks') }

    it 'symlinks the global hooks directory' do
      repository.create_hooks

      expect(File.symlink?(hook_path)).to be true
      expect(File.readlink(hook_path)).to eq(Gitlab.config.gitlab_shell.hooks_path)
    end

    it 'replaces existing symlink with the right directory' do
      FileUtils.mkdir_p(hook_path)

      expect(File.symlink?(hook_path)).to be false

      repository.create_hooks

      expect(File.symlink?(hook_path)).to be true
      expect(File.readlink(hook_path)).to eq(Gitlab.config.gitlab_shell.hooks_path)
    end
  end

  describe "#create_dir" do
    it "commits a change that creates a new directory" do
      expect do
        repository.create_dir(user, 'newdir',
          message: 'Create newdir', branch_name: 'master')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      newdir = repository.tree('master', 'newdir')
      expect(newdir.path).to eq('newdir')
    end

    context "when committing to another project" do
      let(:forked_project) { create(:project, :repository) }

      it "creates a fork and commit to the forked project" do
        expect do
          repository.create_dir(user, 'newdir',
            message: 'Create newdir', branch_name: 'patch',
            start_branch_name: 'master', start_project: forked_project)
        end.to change { repository.count_commits(ref: 'master') }.by(0)

        expect(repository.branch_exists?('patch')).to be_truthy
        expect(forked_project.repository.branch_exists?('patch')).to be_falsy

        newdir = repository.tree('patch', 'newdir')
        expect(newdir.path).to eq('newdir')
      end
    end

    context "when an author is specified" do
      it "uses the given email/name to set the commit's author" do
        expect do
          repository.create_dir(user, 'newdir',
            message: 'Add newdir',
            branch_name: 'master',
            author_email: author_email, author_name: author_name)
        end.to change { repository.count_commits(ref: 'master') }.by(1)

        last_commit = repository.commit

        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end
  end

  describe "#create_file" do
    it 'commits new file successfully' do
      expect do
        repository.create_file(user, 'NEWCHANGELOG', 'Changelog!',
                               message: 'Create changelog',
                               branch_name: 'master')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      blob = repository.blob_at('master', 'NEWCHANGELOG')

      expect(blob.data).to eq('Changelog!')
    end

    it 'creates new file and dir when file_path has a forward slash' do
      expect do
        repository.create_file(user, 'new_dir/new_file.txt', 'File!',
                               message: 'Create new_file with new_dir',
                               branch_name: 'master')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      expect(repository.tree('master', 'new_dir').path).to eq('new_dir')
      expect(repository.blob_at('master', 'new_dir/new_file.txt').data).to eq('File!')
    end

    it 'respects the autocrlf setting' do
      repository.create_file(user, 'hello.txt', "Hello,\r\nWorld",
                             message: 'Add hello world',
                             branch_name: 'master')

      blob = repository.blob_at('master', 'hello.txt')

      expect(blob.data).to eq("Hello,\nWorld")
    end

    context "when an author is specified" do
      it "uses the given email/name to set the commit's author" do
        expect do
          repository.create_file(user, 'NEWREADME', 'README!',
                                 message: 'Add README',
                                 branch_name: 'master',
                                 author_email: author_email,
                                 author_name: author_name)
        end.to change { repository.count_commits(ref: 'master') }.by(1)

        last_commit = repository.commit

        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end
  end

  describe "#update_file" do
    it 'updates file successfully' do
      expect do
        repository.update_file(user, 'CHANGELOG', 'Changelog!',
                               message: 'Update changelog',
                               branch_name: 'master')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      blob = repository.blob_at('master', 'CHANGELOG')

      expect(blob.data).to eq('Changelog!')
    end

    it 'updates filename successfully' do
      expect do
        repository.update_file(user, 'NEWLICENSE', 'Copyright!',
                                     branch_name: 'master',
                                     previous_path: 'LICENSE',
                                     message: 'Changes filename')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      files = repository.ls_files('master')

      expect(files).not_to include('LICENSE')
      expect(files).to include('NEWLICENSE')
    end

    context "when an author is specified" do
      it "uses the given email/name to set the commit's author" do
        expect do
          repository.update_file(user, 'README', 'Updated README!',
                                 branch_name: 'master',
                                 previous_path: 'README',
                                 message: 'Update README',
                                 author_email: author_email,
                                 author_name: author_name)
        end.to change { repository.count_commits(ref: 'master') }.by(1)

        last_commit = repository.commit

        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end
  end

  describe "#delete_file" do
    it 'removes file successfully' do
      expect do
        repository.delete_file(user, 'README',
          message: 'Remove README', branch_name: 'master')
      end.to change { repository.count_commits(ref: 'master') }.by(1)

      expect(repository.blob_at('master', 'README')).to be_nil
    end

    context "when an author is specified" do
      it "uses the given email/name to set the commit's author" do
        expect do
          repository.delete_file(user, 'README',
            message: 'Remove README', branch_name: 'master',
            author_email: author_email, author_name: author_name)
        end.to change { repository.count_commits(ref: 'master') }.by(1)

        last_commit = repository.commit

        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end
  end

  describe "search_files_by_content" do
    let(:results) { repository.search_files_by_content('feature', 'master') }
    subject { results }

    it { is_expected.to be_an Array }

    it 'regex-escapes the query string' do
      results = repository.search_files_by_content("test\\", 'master')

      expect(results.first).not_to start_with('fatal:')
    end

    it 'properly handles an unmatched parenthesis' do
      results = repository.search_files_by_content("test(", 'master')

      expect(results.first).not_to start_with('fatal:')
    end

    it 'properly handles when query is not present' do
      results = repository.search_files_by_content('', 'master')

      expect(results).to match_array([])
    end

    it 'properly handles query when repo is empty' do
      repository = create(:project, :empty_repo).repository
      results = repository.search_files_by_content('test', 'master')

      expect(results).to match_array([])
    end

    describe 'when storage is broken', :broken_storage  do
      it 'should raise a storage error' do
        expect_to_raise_storage_error do
          broken_repository.search_files_by_content('feature', 'master')
        end
      end
    end

    describe 'result' do
      subject { results.first }

      it { is_expected.to be_an String }
      it { expect(subject.lines[2]).to eq("master:CHANGELOG\x00190\x00  - Feature: Replace teams with group membership\n") }
    end
  end

  describe "search_files_by_name" do
    let(:results) { repository.search_files_by_name('files', 'master') }

    it 'returns result' do
      expect(results.first).to eq('files/html/500.html')
    end

    it 'ignores leading slashes' do
      results = repository.search_files_by_name('/files', 'master')

      expect(results.first).to eq('files/html/500.html')
    end

    it 'properly handles when query is only slashes' do
      results = repository.search_files_by_name('//', 'master')

      expect(results).to match_array([])
    end

    it 'properly handles when query is not present' do
      results = repository.search_files_by_name('', 'master')

      expect(results).to match_array([])
    end

    it 'properly handles query when repo is empty' do
      repository = create(:project, :empty_repo).repository

      results = repository.search_files_by_name('test', 'master')

      expect(results).to match_array([])
    end

    describe 'when storage is broken', :broken_storage  do
      it 'should raise a storage error' do
        expect_to_raise_storage_error { broken_repository.search_files_by_name('files', 'master') }
      end
    end
  end

  describe '#async_remove_remote' do
    before do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('joe', 'remote_branch', masterrev)
    end

    context 'when worker is scheduled successfully' do
      before do
        masterrev = repository.find_branch('master').dereferenced_target
        create_remote_branch('remote_name', 'remote_branch', masterrev)

        allow(RepositoryRemoveRemoteWorker).to receive(:perform_async).and_return('1234')
      end

      it 'returns job_id' do
        expect(repository.async_remove_remote('joe')).to eq('1234')
      end
    end

    context 'when worker does not schedule successfully' do
      before do
        allow(RepositoryRemoveRemoteWorker).to receive(:perform_async).and_return(nil)
      end

      it 'returns nil' do
        expect(Rails.logger).to receive(:info).with("Remove remote job failed to create for #{project.id} with remote name joe.")

        expect(repository.async_remove_remote('joe')).to be_nil
      end
    end
  end

  describe '#fetch_ref' do
    let(:broken_repository) { create(:project, :broken_storage).repository }

    describe 'when storage is broken', :broken_storage  do
      it 'should raise a storage error' do
        expect_to_raise_storage_error do
          broken_repository.fetch_ref(broken_repository, source_ref: '1', target_ref: '2')
        end
      end
    end
  end

  describe '#create_ref' do
    it 'redirects the call to write_ref' do
      ref, ref_path = '1', '2'

      expect(repository.raw_repository).to receive(:write_ref).with(ref_path, ref)

      repository.create_ref(ref, ref_path)
    end
  end

  describe "#changelog", :use_clean_rails_memory_store_caching do
    it 'accepts changelog' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('changelog')])

      expect(repository.changelog.path).to eq('changelog')
    end

    it 'accepts news instead of changelog' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('news')])

      expect(repository.changelog.path).to eq('news')
    end

    it 'accepts history instead of changelog' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('history')])

      expect(repository.changelog.path).to eq('history')
    end

    it 'accepts changes instead of changelog' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('changes')])

      expect(repository.changelog.path).to eq('changes')
    end

    it 'is case-insensitive' do
      expect(repository.tree).to receive(:blobs).and_return([TestBlob.new('CHANGELOG')])

      expect(repository.changelog.path).to eq('CHANGELOG')
    end
  end

  describe "#license_blob", :use_clean_rails_memory_store_caching do
    before do
      repository.delete_file(
        user, 'LICENSE', message: 'Remove LICENSE', branch_name: 'master')
    end

    it 'handles when HEAD points to non-existent ref' do
      repository.create_file(
        user, 'LICENSE', 'Copyright!',
        message: 'Add LICENSE', branch_name: 'master')

      allow(repository).to receive(:root_ref).and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository.license_blob).to be_nil
    end

    it 'looks in the root_ref only' do
      repository.delete_file(user, 'LICENSE',
        message: 'Remove LICENSE', branch_name: 'markdown')
      repository.create_file(user, 'LICENSE',
        Licensee::License.new('mit').content,
        message: 'Add LICENSE', branch_name: 'markdown')

      expect(repository.license_blob).to be_nil
    end

    it 'detects license file with no recognizable open-source license content' do
      repository.create_file(user, 'LICENSE', 'Copyright!',
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license_blob.path).to eq('LICENSE')
    end

    %w[LICENSE LICENCE LiCensE LICENSE.md LICENSE.foo COPYING COPYING.md].each do |filename|
      it "detects '#{filename}'" do
        repository.create_file(user, filename,
          Licensee::License.new('mit').content,
          message: "Add #{filename}", branch_name: 'master')

        expect(repository.license_blob.name).to eq(filename)
      end
    end
  end

  describe '#license_key', :use_clean_rails_memory_store_caching do
    before do
      repository.delete_file(user, 'LICENSE',
        message: 'Remove LICENSE', branch_name: 'master')
    end

    it 'returns nil when no license is detected' do
      expect(repository.license_key).to be_nil
    end

    it 'returns nil when the repository does not exist' do
      expect(repository).to receive(:exists?).and_return(false)

      expect(repository.license_key).to be_nil
    end

    it 'returns nil when the content is not recognizable' do
      repository.create_file(user, 'LICENSE', 'Copyright!',
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license_key).to be_nil
    end

    it 'returns nil when the commit SHA does not exist' do
      allow(repository.head_commit).to receive(:sha).and_return('1' * 40)

      expect(repository.license_key).to be_nil
    end

    it 'returns nil when master does not exist' do
      repository.rm_branch(user, 'master')

      expect(repository.license_key).to be_nil
    end

    it 'returns the license key' do
      repository.create_file(user, 'LICENSE',
        Licensee::License.new('mit').content,
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license_key).to eq('mit')
    end
  end

  describe '#license' do
    before do
      repository.delete_file(user, 'LICENSE',
        message: 'Remove LICENSE', branch_name: 'master')
    end

    it 'returns nil when no license is detected' do
      expect(repository.license).to be_nil
    end

    it 'returns nil when the repository does not exist' do
      expect(repository).to receive(:exists?).and_return(false)

      expect(repository.license).to be_nil
    end

    it 'returns nil when the content is not recognizable' do
      repository.create_file(user, 'LICENSE', 'Copyright!',
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license).to be_nil
    end

    it 'returns the license' do
      license = Licensee::License.new('mit')
      repository.create_file(user, 'LICENSE',
        license.content,
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license).to eq(license)
    end
  end

  describe "#gitlab_ci_yml", :use_clean_rails_memory_store_caching do
    it 'returns valid file' do
      files = [TestBlob.new('file'), TestBlob.new('.gitlab-ci.yml'), TestBlob.new('copying')]
      expect(repository.tree).to receive(:blobs).and_return(files)

      expect(repository.gitlab_ci_yml.path).to eq('.gitlab-ci.yml')
    end

    it 'returns nil if not exists' do
      expect(repository.tree).to receive(:blobs).and_return([])
      expect(repository.gitlab_ci_yml).to be_nil
    end

    it 'returns nil for empty repository' do
      allow(repository).to receive(:root_ref).and_raise(Gitlab::Git::Repository::NoRepository)
      expect(repository.gitlab_ci_yml).to be_nil
    end
  end

  describe '#add_branch' do
    let(:branch_name) { 'new_feature' }
    let(:target) { 'master' }

    subject { repository.add_branch(user, branch_name, target) }

    context 'with Gitaly enabled' do
      it "calls Gitaly's OperationService" do
        expect_any_instance_of(Gitlab::GitalyClient::OperationService)
          .to receive(:user_create_branch).with(branch_name, user, target)
          .and_return(nil)

        subject
      end

      it 'creates_the_branch' do
        expect(subject.name).to eq(branch_name)
        expect(repository.find_branch(branch_name)).not_to be_nil
      end

      context 'with a non-existing target' do
        let(:target) { 'fake-target' }

        it "returns false and doesn't create the branch" do
          expect(subject).to be(false)
          expect(repository.find_branch(branch_name)).to be_nil
        end
      end
    end

    context 'with Gitaly disabled', :disable_gitaly do
      context 'when pre hooks were successful' do
        it 'runs without errors' do
          hook = double(trigger: [true, nil])
          expect(Gitlab::Git::Hook).to receive(:new).exactly(3).times.and_return(hook)

          expect { subject }.not_to raise_error
        end

        it 'creates the branch' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])

          expect(subject.name).to eq(branch_name)
        end

        it 'calls the after_create_branch hook' do
          expect(repository).to receive(:after_create_branch)

          subject
        end
      end

      context 'when pre hooks failed' do
        it 'gets an error' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([false, ''])

          expect { subject }.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
        end

        it 'does not create the branch' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([false, ''])

          expect { subject }.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
          expect(repository.find_branch(branch_name)).to be_nil
        end
      end
    end
  end

  describe '#find_branch' do
    context 'fresh_repo is true' do
      it 'delegates the call to raw_repository' do
        expect(repository.raw_repository).to receive(:find_branch).with('master', true)

        repository.find_branch('master', fresh_repo: true)
      end
    end

    context 'fresh_repo is false' do
      it 'delegates the call to raw_repository' do
        expect(repository.raw_repository).to receive(:find_branch).with('master', false)

        repository.find_branch('master', fresh_repo: false)
      end
    end
  end

  describe '#update_branch_with_hooks' do
    let(:old_rev) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' } # git rev-parse feature
    let(:new_rev) { 'a74ae73c1ccde9b974a70e82b901588071dc142a' } # commit whose parent is old_rev
    let(:updating_ref) { 'refs/heads/feature' }
    let(:target_project) { project }
    let(:target_repository) { target_project.repository }

    context 'when pre hooks were successful' do
      before do
        service = Gitlab::Git::HooksService.new
        expect(Gitlab::Git::HooksService).to receive(:new).and_return(service)
        expect(service).to receive(:execute)
          .with(git_user, target_repository.raw_repository, old_rev, new_rev, updating_ref)
          .and_yield(service).and_return(true)
      end

      it 'runs without errors' do
        expect do
          Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch('feature') do
            new_rev
          end
        end.not_to raise_error
      end

      it 'ensures the autocrlf Git option is set to :input' do
        service = Gitlab::Git::OperationService.new(git_user, repository.raw_repository)

        expect(service).to receive(:update_autocrlf_option)

        service.with_branch('feature') { new_rev }
      end

      context "when the branch wasn't empty" do
        it 'updates the head' do
          expect(repository.find_branch('feature').dereferenced_target.id).to eq(old_rev)

          Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch('feature') do
            new_rev
          end

          expect(repository.find_branch('feature').dereferenced_target.id).to eq(new_rev)
        end
      end

      context 'when target project does not have the commit' do
        let(:target_project) { create(:project, :empty_repo) }
        let(:old_rev) { Gitlab::Git::BLANK_SHA }
        let(:new_rev) { project.commit('feature').sha }
        let(:updating_ref) { 'refs/heads/master' }

        it 'fetch_ref and create the branch' do
          expect(target_project.repository.raw_repository).to receive(:fetch_ref)
            .and_call_original

          Gitlab::Git::OperationService.new(git_user, target_repository.raw_repository)
            .with_branch(
              'master',
              start_repository: project.repository.raw_repository,
              start_branch_name: 'feature') { new_rev }

          expect(target_repository.branch_names).to contain_exactly('master')
        end
      end

      context 'when target project already has the commit' do
        let(:target_project) { create(:project, :repository) }

        it 'does not fetch_ref and just pass the commit' do
          expect(target_repository).not_to receive(:fetch_ref)

          Gitlab::Git::OperationService.new(git_user, target_repository.raw_repository)
            .with_branch('feature', start_repository: project.repository.raw_repository) { new_rev }
        end
      end
    end

    context 'when temporary ref failed to be created from other project' do
      let(:target_project) { create(:project, :empty_repo) }

      before do
        expect(target_project.repository.raw_repository).to receive(:run_git)
      end

      it 'raises Rugged::ReferenceError' do
        raise_reference_error = raise_error(Rugged::ReferenceError) do |err|
          expect(err.cause).to be_nil
        end

        expect do
          Gitlab::Git::OperationService.new(git_user, target_project.repository.raw_repository)
            .with_branch('feature',
                         start_repository: project.repository.raw_repository,
                         &:itself)
        end.to raise_reference_error
      end
    end

    context 'when the update adds more than one commit' do
      let(:old_rev) { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }

      it 'runs without errors' do
        # old_rev is an ancestor of new_rev
        expect(repository.merge_base(old_rev, new_rev)).to eq(old_rev)

        # old_rev is not a direct ancestor (parent) of new_rev
        expect(repository.rugged.lookup(new_rev).parent_ids).not_to include(old_rev)

        branch = 'feature-ff-target'
        repository.add_branch(user, branch, old_rev)

        expect do
          Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch(branch) do
            new_rev
          end
        end.not_to raise_error
      end
    end

    context 'when the update would remove commits from the target branch' do
      let(:branch) { 'master' }
      let(:old_rev) { repository.find_branch(branch).dereferenced_target.sha }

      it 'raises an exception' do
        # The 'master' branch is NOT an ancestor of new_rev.
        expect(repository.merge_base(old_rev, new_rev)).not_to eq(old_rev)

        # Updating 'master' to new_rev would lose the commits on 'master' that
        # are not contained in new_rev. This should not be allowed.
        expect do
          Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch(branch) do
            new_rev
          end
        end.to raise_error(Gitlab::Git::CommitError)
      end
    end

    context 'when pre hooks failed' do
      it 'gets an error' do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([false, ''])

        expect do
          Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch('feature') do
            new_rev
          end
        end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
      end
    end

    context 'when target branch is different from source branch' do
      before do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, ''])
      end

      subject do
        Gitlab::Git::OperationService.new(git_user, repository.raw_repository).with_branch('new-feature') do
          new_rev
        end
      end

      it 'returns branch_created as true' do
        expect(subject).not_to be_repo_created
        expect(subject).to     be_branch_created
      end
    end

    context 'when repository is empty' do
      before do
        allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, ''])
      end

      it 'expires creation and branch cache' do
        empty_repository = create(:project, :empty_repo).repository

        expect(empty_repository).to receive(:expire_exists_cache)
        expect(empty_repository).to receive(:expire_root_ref_cache)
        expect(empty_repository).to receive(:expire_emptiness_caches)
        expect(empty_repository).to receive(:expire_branches_cache)

        empty_repository.create_file(user, 'CHANGELOG', 'Changelog!',
                                     message: 'Updates file content',
                                     branch_name: 'master')
      end
    end
  end

  shared_examples 'repo exists check' do
    it 'returns true when a repository exists' do
      expect(repository.exists?).to eq(true)
    end

    it 'returns false if no full path can be constructed' do
      allow(repository).to receive(:full_path).and_return(nil)

      expect(repository.exists?).to eq(false)
    end

    context 'with broken storage', :broken_storage do
      it 'should raise a storage error' do
        expect_to_raise_storage_error { broken_repository.exists? }
      end
    end
  end

  describe '#exists?' do
    context 'when repository_exists is disabled' do
      it_behaves_like 'repo exists check'
    end

    context 'when repository_exists is enabled', :skip_gitaly_mock do
      it_behaves_like 'repo exists check'
    end
  end

  describe '#has_visible_content?' do
    before do
      # If raw_repository.has_visible_content? gets called more than once then
      # caching is broken. We don't want that.
      expect(repository.raw_repository).to receive(:has_visible_content?)
        .once
        .and_return(result)
    end

    context 'when true' do
      let(:result) { true }

      it 'returns true and caches it' do
        expect(repository.has_visible_content?).to eq(true)
        # Second call hits the cache
        expect(repository.has_visible_content?).to eq(true)
      end
    end

    context 'when false' do
      let(:result) { false }

      it 'returns false and caches it' do
        expect(repository.has_visible_content?).to eq(false)
        # Second call hits the cache
        expect(repository.has_visible_content?).to eq(false)
      end
    end
  end

  describe '#branch_exists?' do
    it 'uses branch_names' do
      allow(repository).to receive(:branch_names).and_return(['foobar'])

      expect(repository.branch_exists?('foobar')).to eq(true)
      expect(repository.branch_exists?('master')).to eq(false)
    end
  end

  describe '#tag_exists?' do
    it 'uses tag_names' do
      allow(repository).to receive(:tag_names).and_return(['foobar'])

      expect(repository.tag_exists?('foobar')).to eq(true)
      expect(repository.tag_exists?('master')).to eq(false)
    end
  end

  describe '#branch_names', :use_clean_rails_memory_store_caching do
    let(:fake_branch_names) { ['foobar'] }

    it 'gets cached across Repository instances' do
      allow(repository.raw_repository).to receive(:branch_names).once.and_return(fake_branch_names)

      expect(repository.branch_names).to eq(fake_branch_names)

      fresh_repository = Project.find(project.id).repository
      expect(fresh_repository.object_id).not_to eq(repository.object_id)

      expect(fresh_repository.raw_repository).not_to receive(:branch_names)
      expect(fresh_repository.branch_names).to eq(fake_branch_names)
    end
  end

  describe '#update_autocrlf_option' do
    describe 'when autocrlf is not already set to :input' do
      before do
        repository.raw_repository.autocrlf = true
      end

      it 'sets autocrlf to :input' do
        Gitlab::Git::OperationService.new(nil, repository.raw_repository).send(:update_autocrlf_option)

        expect(repository.raw_repository.autocrlf).to eq(:input)
      end
    end

    describe 'when autocrlf is already set to :input' do
      before do
        repository.raw_repository.autocrlf = :input
      end

      it 'does nothing' do
        expect(repository.raw_repository).not_to receive(:autocrlf=)
          .with(:input)

        Gitlab::Git::OperationService.new(nil, repository.raw_repository).send(:update_autocrlf_option)
      end
    end
  end

  describe '#empty?' do
    let(:empty_repository) { create(:project_empty_repo).repository }

    it 'returns true for an empty repository' do
      expect(empty_repository).to be_empty
    end

    it 'returns false for a non-empty repository' do
      expect(repository).not_to be_empty
    end

    it 'caches the output' do
      expect(repository.raw_repository).to receive(:has_visible_content?).once

      repository.empty?
      repository.empty?
    end
  end

  describe '#root_ref' do
    it 'returns a branch name' do
      expect(repository.root_ref).to be_an_instance_of(String)
    end

    it 'caches the output' do
      expect(repository.raw_repository).to receive(:root_ref)
        .once
        .and_return('master')

      repository.root_ref
      repository.root_ref
    end
  end

  describe '#expire_root_ref_cache' do
    it 'expires the root reference cache' do
      repository.root_ref

      expect(repository.raw_repository).to receive(:root_ref)
        .once
        .and_return('foo')

      repository.expire_root_ref_cache

      expect(repository.root_ref).to eq('foo')
    end
  end

  describe '#expire_branch_cache' do
    # This method is private but we need it for testing purposes. Sadly there's
    # no other proper way of testing caching operations.
    let(:cache) { repository.send(:cache) }

    it 'expires the cache for all branches' do
      expect(cache).to receive(:expire)
        .at_least(repository.branches.length * 2)
        .times

      repository.expire_branch_cache
    end

    it 'expires the cache for all branches when the root branch is given' do
      expect(cache).to receive(:expire)
        .at_least(repository.branches.length * 2)
        .times

      repository.expire_branch_cache(repository.root_ref)
    end

    it 'expires the cache for a specific branch' do
      expect(cache).to receive(:expire).twice

      repository.expire_branch_cache('foo')
    end
  end

  describe '#expire_emptiness_caches' do
    let(:cache) { repository.send(:cache) }

    it 'expires the caches for an empty repository' do
      allow(repository).to receive(:empty?).and_return(true)

      expect(cache).to receive(:expire).with(:has_visible_content?)

      repository.expire_emptiness_caches
    end

    it 'does not expire the cache for a non-empty repository' do
      allow(repository).to receive(:empty?).and_return(false)

      expect(cache).not_to receive(:expire).with(:has_visible_content?)

      repository.expire_emptiness_caches
    end
  end

  describe 'skip_merges option' do
    subject { repository.commits(Gitlab::Git::BRANCH_REF_PREFIX + "'test'", limit: 100, skip_merges: true).map { |k| k.id } }

    it { is_expected.not_to include('e56497bb5f03a90a51293fc6d516788730953899') }
  end

  describe '#merge' do
    let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master', source_project: project) }

    let(:message) { 'Test \r\n\r\n message' }

    shared_examples '#merge' do
      it 'merges the code and returns the commit id' do
        expect(merge_commit).to be_present
        expect(repository.blob_at(merge_commit.id, 'files/ruby/feature.rb')).to be_present
      end

      it 'sets the `in_progress_merge_commit_sha` flag for the given merge request' do
        merge_commit_id = merge(repository, user, merge_request, message)

        expect(merge_request.in_progress_merge_commit_sha).to eq(merge_commit_id)
      end

      it 'removes carriage returns from commit message' do
        merge_commit_id = merge(repository, user, merge_request, message)

        expect(repository.commit(merge_commit_id).message).to eq(message.delete("\r"))
      end
    end

    context 'with gitaly' do
      it_behaves_like '#merge'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#merge'
    end

    def merge(repository, user, merge_request, message)
      repository.merge(user, merge_request.diff_head_sha, merge_request, message)
    end
  end

  describe '#ff_merge' do
    before do
      repository.add_branch(user, 'ff-target', 'feature~5')
    end

    it 'merges the code and return the commit id' do
      merge_request = create(:merge_request, source_branch: 'feature', target_branch: 'ff-target', source_project: project)
      merge_commit_id = repository.ff_merge(user,
                                            merge_request.diff_head_sha,
                                            merge_request.target_branch,
                                            merge_request: merge_request)
      merge_commit = repository.commit(merge_commit_id)

      expect(merge_commit).to be_present
      expect(repository.blob_at(merge_commit.id, 'files/ruby/feature.rb')).to be_present
    end

    it 'sets the `in_progress_merge_commit_sha` flag for the given merge request' do
      merge_request = create(:merge_request, source_branch: 'feature', target_branch: 'ff-target', source_project: project)
      merge_commit_id = repository.ff_merge(user,
                                            merge_request.diff_head_sha,
                                            merge_request.target_branch,
                                            merge_request: merge_request)

      expect(merge_request.in_progress_merge_commit_sha).to eq(merge_commit_id)
    end
  end

  describe '#revert' do
    shared_examples 'reverting a commit' do
      let(:new_image_commit) { repository.commit('33f3729a45c02fc67d00adb1b8bca394b0e761d9') }
      let(:update_image_commit) { repository.commit('2f63565e7aac07bcdadb654e253078b727143ec4') }
      let(:message) { 'revert message' }

      context 'when there is a conflict' do
        it 'raises an error' do
          expect { repository.revert(user, new_image_commit, 'master', message) }.to raise_error(Gitlab::Git::Repository::CreateTreeError)
        end
      end

      context 'when commit was already reverted' do
        it 'raises an error' do
          repository.revert(user, update_image_commit, 'master', message)

          expect { repository.revert(user, update_image_commit, 'master', message) }.to raise_error(Gitlab::Git::Repository::CreateTreeError)
        end
      end

      context 'when commit can be reverted' do
        it 'reverts the changes' do
          expect(repository.revert(user, update_image_commit, 'master', message)).to be_truthy
        end
      end

      context 'reverting a merge commit' do
        it 'reverts the changes' do
          merge_commit
          expect(repository.blob_at_branch('master', 'files/ruby/feature.rb')).to be_present

          repository.revert(user, merge_commit, 'master', message)
          expect(repository.blob_at_branch('master', 'files/ruby/feature.rb')).not_to be_present
        end
      end
    end

    context 'when Gitaly revert feature is enabled' do
      it_behaves_like 'reverting a commit'
    end

    context 'when Gitaly revert feature is disabled', :disable_gitaly do
      it_behaves_like 'reverting a commit'
    end
  end

  describe '#cherry_pick' do
    shared_examples 'cherry-picking a commit' do
      let(:conflict_commit) { repository.commit('c642fe9b8b9f28f9225d7ea953fe14e74748d53b') }
      let(:pickable_commit) { repository.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }
      let(:pickable_merge) { repository.commit('e56497bb5f03a90a51293fc6d516788730953899') }
      let(:message) { 'cherry-pick message' }

      context 'when there is a conflict' do
        it 'raises an error' do
          expect { repository.cherry_pick(user, conflict_commit, 'master', message) }.to raise_error(Gitlab::Git::Repository::CreateTreeError)
        end
      end

      context 'when commit was already cherry-picked' do
        it 'raises an error' do
          repository.cherry_pick(user, pickable_commit, 'master', message)

          expect { repository.cherry_pick(user, pickable_commit, 'master', message) }.to raise_error(Gitlab::Git::Repository::CreateTreeError)
        end
      end

      context 'when commit can be cherry-picked' do
        it 'cherry-picks the changes' do
          expect(repository.cherry_pick(user, pickable_commit, 'master', message)).to be_truthy
        end
      end

      context 'cherry-picking a merge commit' do
        it 'cherry-picks the changes' do
          expect(repository.blob_at_branch('improve/awesome', 'foo/bar/.gitkeep')).to be_nil

          cherry_pick_commit_sha = repository.cherry_pick(user, pickable_merge, 'improve/awesome', message)
          cherry_pick_commit_message = project.commit(cherry_pick_commit_sha).message

          expect(repository.blob_at_branch('improve/awesome', 'foo/bar/.gitkeep')).not_to be_nil
          expect(cherry_pick_commit_message).to eq(message)
        end
      end
    end

    context 'when Gitaly cherry_pick feature is enabled' do
      it_behaves_like 'cherry-picking a commit'
    end

    context 'when Gitaly cherry_pick feature is disabled', :disable_gitaly do
      it_behaves_like 'cherry-picking a commit'
    end
  end

  describe '#before_delete' do
    describe 'when a repository does not exist' do
      before do
        allow(repository).to receive(:exists?).and_return(false)
      end

      it 'does not flush caches that depend on repository data' do
        expect(repository).not_to receive(:expire_cache)

        repository.before_delete
      end

      it 'flushes the tags cache' do
        expect(repository).to receive(:expire_tags_cache)

        repository.before_delete
      end

      it 'flushes the branches cache' do
        expect(repository).to receive(:expire_branches_cache)

        repository.before_delete
      end

      it 'flushes the root ref cache' do
        expect(repository).to receive(:expire_root_ref_cache)

        repository.before_delete
      end

      it 'flushes the emptiness caches' do
        expect(repository).to receive(:expire_emptiness_caches)

        repository.before_delete
      end

      it 'flushes the exists cache' do
        expect(repository).to receive(:expire_exists_cache).twice

        repository.before_delete
      end
    end

    describe 'when a repository exists' do
      before do
        allow(repository).to receive(:exists?).and_return(true)
      end

      it 'flushes the tags cache' do
        expect(repository).to receive(:expire_tags_cache)

        repository.before_delete
      end

      it 'flushes the branches cache' do
        expect(repository).to receive(:expire_branches_cache)

        repository.before_delete
      end

      it 'flushes the root ref cache' do
        expect(repository).to receive(:expire_root_ref_cache)

        repository.before_delete
      end

      it 'flushes the emptiness caches' do
        expect(repository).to receive(:expire_emptiness_caches)

        repository.before_delete
      end
    end
  end

  describe '#before_change_head' do
    it 'flushes the branch cache' do
      expect(repository).to receive(:expire_branch_cache)

      repository.before_change_head
    end

    it 'flushes the root ref cache' do
      expect(repository).to receive(:expire_root_ref_cache)

      repository.before_change_head
    end
  end

  describe '#after_change_head' do
    it 'flushes the readme cache' do
      expect(repository).to receive(:expire_method_caches).with([
        :readme,
        :changelog,
        :license,
        :contributing,
        :gitignore,
        :koding,
        :gitlab_ci,
        :avatar,
        :issue_template,
        :merge_request_template
      ])

      repository.after_change_head
    end
  end

  describe '#before_push_tag' do
    it 'flushes the cache' do
      expect(repository).to receive(:expire_statistics_caches)
      expect(repository).to receive(:expire_emptiness_caches)
      expect(repository).to receive(:expire_tags_cache)

      repository.before_push_tag
    end
  end

  describe '#after_import' do
    it 'flushes and builds the cache' do
      expect(repository).to receive(:expire_content_cache)

      repository.after_import
    end
  end

  describe '#after_push_commit' do
    it 'expires statistics caches' do
      expect(repository).to receive(:expire_statistics_caches)
        .and_call_original

      expect(repository).to receive(:expire_branch_cache)
        .with('master')
        .and_call_original

      repository.after_push_commit('master')
    end
  end

  describe '#after_create_branch' do
    it 'expires the branch caches' do
      expect(repository).to receive(:expire_branches_cache)

      repository.after_create_branch
    end
  end

  describe '#after_remove_branch' do
    it 'expires the branch caches' do
      expect(repository).to receive(:expire_branches_cache)

      repository.after_remove_branch
    end
  end

  describe '#after_create' do
    it 'flushes the exists cache' do
      expect(repository).to receive(:expire_exists_cache)

      repository.after_create
    end

    it 'flushes the root ref cache' do
      expect(repository).to receive(:expire_root_ref_cache)

      repository.after_create
    end

    it 'flushes the emptiness caches' do
      expect(repository).to receive(:expire_emptiness_caches)

      repository.after_create
    end
  end

  describe "#copy_gitattributes" do
    it 'returns true with a valid ref' do
      expect(repository.copy_gitattributes('master')).to be_truthy
    end

    it 'returns false with an invalid ref' do
      expect(repository.copy_gitattributes('invalid')).to be_falsey
    end
  end

  describe '#before_remove_tag' do
    it 'flushes the tag cache' do
      expect(repository).to receive(:expire_tags_cache).and_call_original
      expect(repository).to receive(:expire_statistics_caches).and_call_original

      repository.before_remove_tag
    end
  end

  describe '#branch_count' do
    it 'returns the number of branches' do
      expect(repository.branch_count).to be_an(Integer)

      # NOTE: Until rugged goes away, make sure rugged and gitaly are in sync
      rugged_count = repository.raw_repository.rugged.branches.count

      expect(repository.branch_count).to eq(rugged_count)
    end
  end

  describe '#tag_count' do
    it 'returns the number of tags' do
      expect(repository.tag_count).to be_an(Integer)

      # NOTE: Until rugged goes away, make sure rugged and gitaly are in sync
      rugged_count = repository.raw_repository.rugged.tags.count

      expect(repository.tag_count).to eq(rugged_count)
    end
  end

  describe '#expire_branches_cache' do
    it 'expires the cache' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(branch_names branch_count has_visible_content?))
        .and_call_original

      repository.expire_branches_cache
    end
  end

  describe '#expire_tags_cache' do
    it 'expires the cache' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(tag_names tag_count))
        .and_call_original

      repository.expire_tags_cache
    end
  end

  describe '#add_tag' do
    let(:user) { build_stubbed(:user) }

    shared_examples 'adding tag' do
      context 'with a valid target' do
        it 'creates the tag' do
          repository.add_tag(user, '8.5', 'master', 'foo')

          tag = repository.find_tag('8.5')
          expect(tag).to be_present
          expect(tag.message).to eq('foo')
          expect(tag.dereferenced_target.id).to eq(repository.commit('master').id)
        end

        it 'returns a Gitlab::Git::Tag object' do
          tag = repository.add_tag(user, '8.5', 'master', 'foo')

          expect(tag).to be_a(Gitlab::Git::Tag)
        end
      end

      context 'with an invalid target' do
        it 'returns false' do
          expect(repository.add_tag(user, '8.5', 'bar', 'foo')).to be false
        end
      end
    end

    context 'when Gitaly operation_user_add_tag feature is enabled' do
      it_behaves_like 'adding tag'
    end

    context 'when Gitaly operation_user_add_tag feature is disabled', :disable_gitaly do
      it_behaves_like 'adding tag'

      it 'passes commit SHA to pre-receive and update hooks and tag SHA to post-receive hook' do
        pre_receive_hook = Gitlab::Git::Hook.new('pre-receive', project)
        update_hook = Gitlab::Git::Hook.new('update', project)
        post_receive_hook = Gitlab::Git::Hook.new('post-receive', project)

        allow(Gitlab::Git::Hook).to receive(:new)
          .and_return(pre_receive_hook, update_hook, post_receive_hook)

        allow(pre_receive_hook).to receive(:trigger).and_call_original
        allow(update_hook).to receive(:trigger).and_call_original
        allow(post_receive_hook).to receive(:trigger).and_call_original

        tag = repository.add_tag(user, '8.5', 'master', 'foo')

        commit_sha = repository.commit('master').id
        tag_sha = tag.target

        expect(pre_receive_hook).to have_received(:trigger)
          .with(anything, anything, anything, commit_sha, anything)
        expect(update_hook).to have_received(:trigger)
          .with(anything, anything, anything, commit_sha, anything)
        expect(post_receive_hook).to have_received(:trigger)
          .with(anything, anything, anything, tag_sha, anything)
      end
    end
  end

  describe '#rm_branch' do
    shared_examples "user deleting a branch" do
      it 'removes a branch' do
        expect(repository).to receive(:before_remove_branch)
        expect(repository).to receive(:after_remove_branch)

        repository.rm_branch(user, 'feature')
      end
    end

    context 'with gitaly enabled' do
      it_behaves_like "user deleting a branch"

      context 'when pre hooks failed' do
        before do
          allow_any_instance_of(Gitlab::GitalyClient::OperationService)
            .to receive(:user_delete_branch).and_raise(Gitlab::Git::HooksService::PreReceiveError)
        end

        it 'gets an error and does not delete the branch' do
          expect do
            repository.rm_branch(user, 'feature')
          end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)

          expect(repository.find_branch('feature')).not_to be_nil
        end
      end
    end

    context 'with gitaly disabled', :disable_gitaly do
      it_behaves_like "user deleting a branch"

      let(:old_rev) { '0b4bc9a49b562e85de7cc9e834518ea6828729b9' } # git rev-parse feature
      let(:blank_sha) { '0000000000000000000000000000000000000000' }

      context 'when pre hooks were successful' do
        it 'runs without errors' do
          expect_any_instance_of(Gitlab::Git::HooksService).to receive(:execute)
            .with(git_user, repository.raw_repository, old_rev, blank_sha, 'refs/heads/feature')

          expect { repository.rm_branch(user, 'feature') }.not_to raise_error
        end

        it 'deletes the branch' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([true, nil])

          expect { repository.rm_branch(user, 'feature') }.not_to raise_error

          expect(repository.find_branch('feature')).to be_nil
        end
      end

      context 'when pre hooks failed' do
        it 'gets an error' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([false, ''])

          expect do
            repository.rm_branch(user, 'feature')
          end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
        end

        it 'does not delete the branch' do
          allow_any_instance_of(Gitlab::Git::Hook).to receive(:trigger).and_return([false, ''])

          expect do
            repository.rm_branch(user, 'feature')
          end.to raise_error(Gitlab::Git::HooksService::PreReceiveError)
          expect(repository.find_branch('feature')).not_to be_nil
        end
      end
    end
  end

  describe '#rm_tag' do
    shared_examples 'removing tag' do
      it 'removes a tag' do
        expect(repository).to receive(:before_remove_tag)

        repository.rm_tag(build_stubbed(:user), 'v1.1.0')

        expect(repository.find_tag('v1.1.0')).to be_nil
      end
    end

    context 'when Gitaly operation_user_delete_tag feature is enabled' do
      it_behaves_like 'removing tag'
    end

    context 'when Gitaly operation_user_delete_tag feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'removing tag'
    end
  end

  describe '#avatar' do
    it 'returns nil if repo does not exist' do
      allow(repository).to receive(:root_ref).and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository.avatar).to eq(nil)
    end

    it 'returns the first avatar file found in the repository' do
      expect(repository).to receive(:file_on_head)
        .with(:avatar)
        .and_return(double(:tree, path: 'logo.png'))

      expect(repository.avatar).to eq('logo.png')
    end

    it 'caches the output' do
      expect(repository).to receive(:file_on_head)
        .with(:avatar)
        .once
        .and_return(double(:tree, path: 'logo.png'))

      2.times { expect(repository.avatar).to eq('logo.png') }
    end
  end

  describe '#expire_exists_cache' do
    let(:cache) { repository.send(:cache) }

    it 'expires the cache' do
      expect(cache).to receive(:expire).with(:exists?)

      repository.expire_exists_cache
    end
  end

  describe "#keep_around" do
    it "does not fail if we attempt to reference bad commit" do
      expect(repository.kept_around?('abc1234')).to be_falsey
    end

    it "stores a reference to the specified commit sha so it isn't garbage collected" do
      repository.keep_around(sample_commit.id)

      expect(repository.kept_around?(sample_commit.id)).to be_truthy
    end

    it "attempting to call keep_around on truncated ref does not fail" do
      repository.keep_around(sample_commit.id)
      ref = repository.send(:keep_around_ref_name, sample_commit.id)
      path = File.join(repository.path, ref)
      # Corrupt the reference
      File.truncate(path, 0)

      expect(repository.kept_around?(sample_commit.id)).to be_falsey

      repository.keep_around(sample_commit.id)

      expect(repository.kept_around?(sample_commit.id)).to be_falsey

      File.delete(path)
    end
  end

  describe '#update_ref' do
    it 'can create a ref' do
      Gitlab::Git::OperationService.new(nil, repository.raw_repository).send(:update_ref, 'refs/heads/foobar', 'refs/heads/master', Gitlab::Git::BLANK_SHA)

      expect(repository.find_branch('foobar')).not_to be_nil
    end

    it 'raises CommitError when the ref update fails' do
      expect do
        Gitlab::Git::OperationService.new(nil, repository.raw_repository).send(:update_ref, 'refs/heads/master', 'refs/heads/master', Gitlab::Git::BLANK_SHA)
      end.to raise_error(Gitlab::Git::CommitError)
    end
  end

  describe '#contribution_guide', :use_clean_rails_memory_store_caching do
    it 'returns and caches the output' do
      expect(repository).to receive(:file_on_head)
        .with(:contributing)
        .and_return(Gitlab::Git::Tree.new(path: 'CONTRIBUTING.md'))
        .once

      2.times do
        expect(repository.contribution_guide)
          .to be_an_instance_of(Gitlab::Git::Tree)
      end
    end
  end

  describe '#gitignore', :use_clean_rails_memory_store_caching do
    it 'returns and caches the output' do
      expect(repository).to receive(:file_on_head)
        .with(:gitignore)
        .and_return(Gitlab::Git::Tree.new(path: '.gitignore'))
        .once

      2.times do
        expect(repository.gitignore).to be_an_instance_of(Gitlab::Git::Tree)
      end
    end
  end

  describe '#koding_yml', :use_clean_rails_memory_store_caching do
    it 'returns and caches the output' do
      expect(repository).to receive(:file_on_head)
        .with(:koding)
        .and_return(Gitlab::Git::Tree.new(path: '.koding.yml'))
        .once

      2.times do
        expect(repository.koding_yml).to be_an_instance_of(Gitlab::Git::Tree)
      end
    end
  end

  describe '#readme', :use_clean_rails_memory_store_caching do
    context 'with a non-existing repository' do
      it 'returns nil' do
        allow(repository).to receive(:tree).with(:head).and_return(nil)

        expect(repository.readme).to be_nil
      end
    end

    context 'with an existing repository' do
      context 'when no README exists' do
        it 'returns nil' do
          allow_any_instance_of(Tree).to receive(:readme).and_return(nil)

          expect(repository.readme).to be_nil
        end
      end

      context 'when a README exists' do
        it 'returns the README' do
          expect(repository.readme).to be_an_instance_of(ReadmeBlob)
        end
      end
    end
  end

  describe '#expire_statistics_caches' do
    it 'expires the caches' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(size commit_count))

      repository.expire_statistics_caches
    end
  end

  describe '#expire_all_method_caches' do
    it 'expires the caches of all methods' do
      expect(repository).to receive(:expire_method_caches)
        .with(Repository::CACHED_METHODS)

      repository.expire_all_method_caches
    end

    it 'all cache_method definitions are in the lists of method caches' do
      methods = repository.methods.map do |method|
        match = /^_uncached_(.*)/.match(method)
        match[1].to_sym if match
      end.compact

      expect(methods).to match_array(Repository::CACHED_METHODS + Repository::MEMOIZED_CACHED_METHODS)
    end
  end

  describe '#file_on_head' do
    context 'with a non-existing repository' do
      it 'returns nil' do
        expect(repository).to receive(:tree).with(:head).and_return(nil)

        expect(repository.file_on_head(:readme)).to be_nil
      end
    end

    context 'with a repository that has no blobs' do
      it 'returns nil' do
        expect_any_instance_of(Tree).to receive(:blobs).and_return([])

        expect(repository.file_on_head(:readme)).to be_nil
      end
    end

    context 'with an existing repository' do
      it 'returns a Gitlab::Git::Tree' do
        expect(repository.file_on_head(:readme))
          .to be_an_instance_of(Gitlab::Git::Tree)
      end
    end
  end

  describe '#head_tree' do
    context 'with an existing repository' do
      it 'returns a Tree' do
        expect(repository.head_tree).to be_an_instance_of(Tree)
      end
    end

    context 'with a non-existing repository' do
      it 'returns nil' do
        expect(repository).to receive(:head_commit).and_return(nil)

        expect(repository.head_tree).to be_nil
      end
    end
  end

  describe '#tree' do
    context 'using a non-existing repository' do
      before do
        allow(repository).to receive(:head_commit).and_return(nil)
      end

      it 'returns nil' do
        expect(repository.tree(:head)).to be_nil
      end

      it 'returns nil when using a path' do
        expect(repository.tree(:head, 'README.md')).to be_nil
      end
    end

    context 'using an existing repository' do
      it 'returns a Tree' do
        expect(repository.tree(:head)).to be_an_instance_of(Tree)
      end
    end
  end

  describe '#size' do
    context 'with a non-existing repository' do
      it 'returns 0' do
        expect(repository).to receive(:exists?).and_return(false)

        expect(repository.size).to eq(0.0)
      end
    end

    context 'with an existing repository' do
      it 'returns the repository size as a Float' do
        expect(repository.size).to be_an_instance_of(Float)
      end
    end
  end

  describe '#local_branches' do
    it 'returns the local branches' do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('joe', 'remote_branch', masterrev)
      repository.add_branch(user, 'local_branch', masterrev.id)

      expect(repository.local_branches.any? { |branch| branch.name == 'remote_branch' }).to eq(false)
      expect(repository.local_branches.any? { |branch| branch.name == 'local_branch' }).to eq(true)
    end
  end

  describe '#remote_branches' do
    it 'returns the remote branches' do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('joe', 'remote_branch', masterrev)
      repository.add_branch(user, 'local_branch', masterrev.id)

      expect(repository.remote_branches('joe').any? { |branch| branch.name == 'local_branch' }).to eq(false)
      expect(repository.remote_branches('joe').any? { |branch| branch.name == 'remote_branch' }).to eq(true)
    end
  end

  describe '#upstream_branches' do
    it 'returns branches from the upstream remote' do
      masterrev = repository.find_branch('master').dereferenced_target
      create_remote_branch('upstream', 'upstream_branch', masterrev)

      expect(repository.upstream_branches.size).to eq(1)
      expect(repository.upstream_branches.first).to be_an_instance_of(Gitlab::Git::Branch)
      expect(repository.upstream_branches.first.name).to eq('upstream_branch')
    end
  end

  describe '#commit_count' do
    context 'with a non-existing repository' do
      it 'returns 0' do
        expect(repository).to receive(:root_ref).and_return(nil)

        expect(repository.commit_count).to eq(0)
      end
    end

    context 'with an existing repository' do
      it 'returns the commit count' do
        expect(repository.commit_count).to be_an(Integer)
      end
    end
  end

  describe '#commit_count_for_ref' do
    let(:project) { create :project }

    context 'with a non-existing repository' do
      it 'returns 0' do
        expect(project.repository.commit_count_for_ref('master')).to eq(0)
      end
    end

    context 'with empty repository' do
      it 'returns 0' do
        project.create_repository
        expect(project.repository.commit_count_for_ref('master')).to eq(0)
      end
    end

    context 'when searching for the root ref' do
      it 'returns the same count as #commit_count' do
        expect(repository.commit_count_for_ref(repository.root_ref)).to eq(repository.commit_count)
      end
    end
  end

  describe '#diverging_commit_counts' do
    it 'returns the commit counts behind and ahead of default branch' do
      result = repository.diverging_commit_counts(
        repository.find_branch('fix'))

      expect(result).to eq(behind: 29, ahead: 2)
    end
  end

  describe '#refresh_method_caches' do
    it 'refreshes the caches of the given types' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(rendered_readme license_blob license_key license))

      expect(repository).to receive(:rendered_readme)
      expect(repository).to receive(:license_blob)
      expect(repository).to receive(:license_key)
      expect(repository).to receive(:license)

      repository.refresh_method_caches(%i(readme license))
    end
  end

  describe '#gitlab_ci_yml_for' do
    before do
      repository.create_file(User.last, '.gitlab-ci.yml', 'CONTENT', message: 'Add .gitlab-ci.yml', branch_name: 'master')
    end

    context 'when there is a .gitlab-ci.yml at the commit' do
      it 'returns the content' do
        expect(repository.gitlab_ci_yml_for(repository.commit.sha)).to eq('CONTENT')
      end
    end

    context 'when there is no .gitlab-ci.yml at the commit' do
      it 'returns nil' do
        expect(repository.gitlab_ci_yml_for(repository.commit.parent.sha)).to be_nil
      end
    end
  end

  describe '#route_map_for' do
    before do
      repository.create_file(User.last, '.gitlab/route-map.yml', 'CONTENT', message: 'Add .gitlab/route-map.yml', branch_name: 'master')
    end

    context 'when there is a .gitlab/route-map.yml at the commit' do
      it 'returns the content' do
        expect(repository.route_map_for(repository.commit.sha)).to eq('CONTENT')
      end
    end

    context 'when there is no .gitlab/route-map.yml at the commit' do
      it 'returns nil' do
        expect(repository.route_map_for(repository.commit.parent.sha)).to be_nil
      end
    end
  end

  describe '#after_sync' do
    it 'expires repository cache' do
      expect(repository).to receive(:expire_all_method_caches)
      expect(repository).to receive(:expire_branch_cache)
      expect(repository).to receive(:expire_content_cache)

      repository.after_sync
    end
  end

  def create_remote_branch(remote_name, branch_name, target)
    rugged = repository.rugged
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end

  describe '#ancestor?' do
    let(:commit) { repository.commit }
    let(:ancestor) { commit.parents.first }

    shared_examples '#ancestor?' do
      it 'it is an ancestor' do
        expect(repository.ancestor?(ancestor.id, commit.id)).to eq(true)
      end

      it 'it is not an ancestor' do
        expect(repository.ancestor?(commit.id, ancestor.id)).to eq(false)
      end

      it 'returns false on nil-values' do
        expect(repository.ancestor?(nil, commit.id)).to eq(false)
        expect(repository.ancestor?(ancestor.id, nil)).to eq(false)
        expect(repository.ancestor?(nil, nil)).to eq(false)
      end

      it 'returns false for invalid commit IDs' do
        expect(repository.ancestor?(commit.id, Gitlab::Git::BLANK_SHA)).to eq(false)
        expect(repository.ancestor?( Gitlab::Git::BLANK_SHA, commit.id)).to eq(false)
      end
    end

    context 'with Gitaly enabled' do
      it_behaves_like('#ancestor?')
    end

    context 'with Gitaly disabled', :skip_gitaly_mock do
      it_behaves_like('#ancestor?')
    end
  end

  describe 'commit cache' do
    set(:project) { create(:project, :repository) }

    it 'caches based on SHA' do
      # Gets the commit oid, and warms the cache
      oid = project.commit.id

      expect(Gitlab::Git::Commit).not_to receive(:find).once

      project.commit_by(oid: oid)
    end

    it 'caches nil values' do
      expect(Gitlab::Git::Commit).to receive(:find).once

      project.commit_by(oid: '1' * 40)
      project.commit_by(oid: '1' * 40)
    end
  end

  describe '#raw_repository' do
    subject { repository.raw_repository }

    it 'returns a Gitlab::Git::Repository representation of the repository' do
      expect(subject).to be_a(Gitlab::Git::Repository)
      expect(subject.relative_path).to eq(project.disk_path + '.git')
      expect(subject.gl_repository).to eq("project-#{project.id}")
    end

    context 'with a wiki repository' do
      let(:repository) { project.wiki.repository }

      it 'creates a Gitlab::Git::Repository with the proper attributes' do
        expect(subject).to be_a(Gitlab::Git::Repository)
        expect(subject.relative_path).to eq(project.disk_path + '.wiki.git')
        expect(subject.gl_repository).to eq("wiki-#{project.id}")
      end
    end
  end

  describe '#contributors' do
    let(:author_a) { build(:author, email: 'tiagonbotelho@hotmail.com', name: 'tiagonbotelho') }
    let(:author_b) { build(:author, email: 'gitlab@winniehell.de', name: 'Winnie') }
    let(:author_c) { build(:author, email: 'douwe@gitlab.com', name: 'Douwe Maan') }
    let(:stubbed_commits) do
      [build(:commit, author: author_a),
       build(:commit, author: author_a),
       build(:commit, author: author_b),
       build(:commit, author: author_c),
       build(:commit, author: author_c),
       build(:commit, author: author_c)]
    end
    let(:order_by) { nil }
    let(:sort) { nil }

    before do
      allow(repository).to receive(:commits).with(nil, limit: 2000, offset: 0, skip_merges: true).and_return(stubbed_commits)
    end

    subject { repository.contributors(order_by: order_by, sort: sort) }

    def expect_contributors(*contributors)
      expect(subject.map(&:email)).to eq(contributors.map(&:email))
    end

    it 'returns the array of Gitlab::Contributor for the repository' do
      expect_contributors(author_a, author_b, author_c)
    end

    context 'order_by email' do
      let(:order_by) { 'email' }

      context 'asc' do
        let(:sort) { 'asc' }

        it 'returns all the contributors ordered by email asc case insensitive' do
          expect_contributors(author_c, author_b, author_a)
        end
      end

      context 'desc' do
        let(:sort) { 'desc' }

        it 'returns all the contributors ordered by email desc case insensitive' do
          expect_contributors(author_a, author_b, author_c)
        end
      end
    end

    context 'order_by name' do
      let(:order_by) { 'name' }

      context 'asc' do
        let(:sort) { 'asc' }

        it 'returns all the contributors ordered by name asc case insensitive' do
          expect_contributors(author_c, author_a, author_b)
        end
      end

      context 'desc' do
        let(:sort) { 'desc' }

        it 'returns all the contributors ordered by name desc case insensitive' do
          expect_contributors(author_b, author_a, author_c)
        end
      end
    end

    context 'order_by commits' do
      let(:order_by) { 'commits' }

      context 'asc' do
        let(:sort) { 'asc' }

        it 'returns all the contributors ordered by commits asc' do
          expect_contributors(author_b, author_a, author_c)
        end
      end

      context 'desc' do
        let(:sort) { 'desc' }

        it 'returns all the contributors ordered by commits desc' do
          expect_contributors(author_c, author_a, author_b)
        end
      end
    end

    context 'invalid ordering' do
      let(:order_by) { 'unknown' }

      it 'returns the contributors unsorted' do
        expect_contributors(author_a, author_b, author_c)
      end
    end

    context 'invalid sorting' do
      let(:order_by) { 'name' }
      let(:sort) { 'unknown' }

      it 'returns the contributors unsorted' do
        expect_contributors(author_a, author_b, author_c)
      end
    end
  end
end
