# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Repository, :seed_helper do
  include Gitlab::EncodingHelper
  include RepoHelpers
  using RSpec::Parameterized::TableSyntax

  shared_examples 'wrapping gRPC errors' do |gitaly_client_class, gitaly_client_method|
    it 'wraps gRPC not found error' do
      expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method)
        .and_raise(GRPC::NotFound)
      expect { subject }.to raise_error(Gitlab::Git::Repository::NoRepository)
    end

    it 'wraps gRPC unknown error' do
      expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method)
        .and_raise(GRPC::Unknown)
      expect { subject }.to raise_error(Gitlab::Git::CommandError)
    end
  end

  let(:mutable_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '', 'group/project') }
  let(:mutable_repository_path) { File.join(TestEnv.repos_path, mutable_repository.relative_path) }
  let(:mutable_repository_rugged) { Rugged::Repository.new(mutable_repository_path) }
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:repository_path) { File.join(TestEnv.repos_path, repository.relative_path) }
  let(:repository_rugged) { Rugged::Repository.new(repository_path) }
  let(:storage_path) { TestEnv.repos_path }
  let(:user) { build(:user) }

  describe "Respond to" do
    subject { repository }

    it { is_expected.to respond_to(:root_ref) }
    it { is_expected.to respond_to(:tags) }
  end

  describe '#root_ref' do
    it 'returns UTF-8' do
      expect(repository.root_ref).to be_utf8
    end

    it 'gets the branch name from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:default_branch_name)
      repository.root_ref
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :default_branch_name do
      subject { repository.root_ref }
    end
  end

  describe '#create_repository' do
    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :create_repository do
      subject { repository.create_repository }
    end
  end

  describe '#branch_names' do
    subject { repository.branch_names }

    it 'has SeedRepo::Repo::BRANCHES.size elements' do
      expect(subject.size).to eq(SeedRepo::Repo::BRANCHES.size)
    end

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end

    it { is_expected.to include("master") }
    it { is_expected.not_to include("branch-from-space") }

    it 'gets the branch names from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:branch_names)
      subject
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :branch_names
  end

  describe '#tag_names' do
    subject { repository.tag_names }

    it { is_expected.to be_kind_of Array }

    it 'has SeedRepo::Repo::TAGS.size elements' do
      expect(subject.size).to eq(SeedRepo::Repo::TAGS.size)
    end

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end

    describe '#last' do
      subject { super().last }

      it { is_expected.to eq("v1.2.1") }
    end
    it { is_expected.to include("v1.0.0") }
    it { is_expected.not_to include("v5.0.0") }

    it 'gets the tag names from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:tag_names)
      subject
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :tag_names
  end

  describe '#archive_metadata' do
    let(:storage_path) { '/tmp' }
    let(:cache_key) { File.join(repository.gl_repository, SeedRepo::LastCommit::ID) }

    let(:append_sha) { true }
    let(:ref) { 'master' }
    let(:format) { nil }
    let(:path) { nil }

    let(:expected_extension) { 'tar.gz' }
    let(:expected_filename) { "#{expected_prefix}.#{expected_extension}" }
    let(:expected_path) { File.join(storage_path, cache_key, "@v2", expected_filename) }
    let(:expected_prefix) { "gitlab-git-test-#{ref}-#{SeedRepo::LastCommit::ID}" }

    subject(:metadata) { repository.archive_metadata(ref, storage_path, 'gitlab-git-test', format, append_sha: append_sha, path: path) }

    it 'sets CommitId to the commit SHA' do
      expect(metadata['CommitId']).to eq(SeedRepo::LastCommit::ID)
    end

    it 'sets ArchivePrefix to the expected prefix' do
      expect(metadata['ArchivePrefix']).to eq(expected_prefix)
    end

    it 'sets ArchivePath to the expected globally-unique path' do
      expect(expected_path).to include(File.join(repository.gl_repository, SeedRepo::LastCommit::ID))

      expect(metadata['ArchivePath']).to eq(expected_path)
    end

    context 'path is set' do
      let(:path) { 'foo/bar' }

      it 'appends the path to the prefix' do
        expect(metadata['ArchivePrefix']).to eq("#{expected_prefix}-foo-bar")
      end
    end

    context 'append_sha varies archive path and filename' do
      where(:append_sha, :ref, :expected_prefix) do
        sha = SeedRepo::LastCommit::ID

        true  | 'master' | "gitlab-git-test-master-#{sha}"
        true  | sha      | "gitlab-git-test-#{sha}-#{sha}"
        false | 'master' | "gitlab-git-test-master"
        false | sha      | "gitlab-git-test-#{sha}"
        nil   | 'master' | "gitlab-git-test-master-#{sha}"
        nil   | sha      | "gitlab-git-test-#{sha}"
      end

      with_them do
        it { expect(metadata['ArchivePrefix']).to eq(expected_prefix) }
        it { expect(metadata['ArchivePath']).to eq(expected_path) }
      end
    end

    context 'format varies archive path and filename' do
      where(:format, :expected_extension) do
        nil      | 'tar.gz'
        'madeup' | 'tar.gz'
        'tbz2'   | 'tar.bz2'
        'zip'    | 'zip'
      end

      with_them do
        it { expect(metadata['ArchivePrefix']).to eq(expected_prefix) }
        it { expect(metadata['ArchivePath']).to eq(expected_path) }
      end
    end
  end

  describe '#size' do
    subject { repository.size }

    it { is_expected.to be < 2 }
  end

  describe '#to_s' do
    subject { repository.to_s }

    it { is_expected.to eq("<Gitlab::Git::Repository: group/project>") }
  end

  describe '#object_directory_size' do
    before do
      allow(repository.gitaly_repository_client)
        .to receive(:get_object_directory_size)
        .and_return(2)
    end

    subject { repository.object_directory_size }

    it { is_expected.to eq 2048 }
  end

  describe '#empty?' do
    it { expect(repository).not_to be_empty }
  end

  describe '#ref_names' do
    let(:ref_names) { repository.ref_names }

    subject { ref_names }

    it { is_expected.to be_kind_of Array }

    describe '#first' do
      subject { super().first }

      it { is_expected.to eq('feature') }
    end

    describe '#last' do
      subject { super().last }

      it { is_expected.to eq('v1.2.1') }
    end
  end

  describe '#submodule_url_for' do
    let(:ref) { 'master' }

    def submodule_url(path)
      repository.submodule_url_for(ref, path)
    end

    it { expect(submodule_url('six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('nested/six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('deeper/nested/six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('invalid/path')).to eq(nil) }

    context 'uncommitted submodule dir' do
      let(:ref) { 'fix-existing-submodule-dir' }

      it { expect(submodule_url('submodule-existing-dir')).to eq(nil) }
    end

    context 'tags' do
      let(:ref) { 'v1.2.1' }

      it { expect(submodule_url('six')).to eq('git://github.com/randx/six.git') }
    end

    context 'no .gitmodules at commit' do
      let(:ref) { '9596bc54a6f0c0c98248fe97077eb5ccf48a98d0' }

      it { expect(submodule_url('six')).to eq(nil) }
    end

    context 'no gitlink entry' do
      let(:ref) { '6d39438' }

      it { expect(submodule_url('six')).to eq(nil) }
    end
  end

  describe '#submodule_urls_for' do
    let(:ref) { 'master' }

    it 'returns url mappings for submodules' do
      urls = repository.submodule_urls_for(ref)

      expect(urls).to eq({
        "deeper/nested/six" => "git://github.com/randx/six.git",
               "gitlab-grack" => "https://gitlab.com/gitlab-org/gitlab-grack.git",
       "gitlab-shell" => "https://github.com/gitlabhq/gitlab-shell.git",
        "nested/six" => "git://github.com/randx/six.git",
        "six" => "git://github.com/randx/six.git"
      })
    end
  end

  describe '#commit_count' do
    it { expect(repository.commit_count("master")).to eq(25) }
    it { expect(repository.commit_count("feature")).to eq(9) }
    it { expect(repository.commit_count("does-not-exist")).to eq(0) }

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::CommitService, :commit_count do
      subject { repository.commit_count('master') }
    end
  end

  describe '#diverging_commit_count' do
    it 'counts 0 for the same branch' do
      expect(repository.diverging_commit_count('master', 'master', max_count: 1000)).to eq([0, 0])
    end

    context 'max count does not truncate results' do
      where(:left, :right, :expected) do
        1 | 1 | [1, 1]
        4 | 4 | [4, 4]
        2 | 2 | [2, 2]
        2 | 4 | [2, 4]
        4 | 2 | [4, 2]
        10 | 10 | [10, 10]
      end

      with_them do
        before do
          repository.create_branch('left-branch')
          repository.create_branch('right-branch')

          left.times do
            new_commit_edit_new_file_on_branch(repository_rugged, 'encoding/CHANGELOG', 'left-branch', 'some more content for a', 'some stuff')
          end

          right.times do
            new_commit_edit_new_file_on_branch(repository_rugged, 'encoding/CHANGELOG', 'right-branch', 'some more content for b', 'some stuff')
          end
        end

        after do
          repository.delete_branch('left-branch')
          repository.delete_branch('right-branch')
        end

        it 'returns the correct count bounding at max_count' do
          branch_a_sha = repository_rugged.branches['left-branch'].target.oid
          branch_b_sha = repository_rugged.branches['right-branch'].target.oid

          count = repository.diverging_commit_count(branch_a_sha, branch_b_sha, max_count: 1000)

          expect(count).to eq(expected)
        end
      end
    end

    context 'max count truncates results' do
      where(:left, :right, :max_count) do
        1 | 1 | 1
        4 | 4 | 4
        2 | 2 | 3
        2 | 4 | 3
        4 | 2 | 5
        10 | 10 | 10
      end

      with_them do
        before do
          repository.create_branch('left-branch')
          repository.create_branch('right-branch')

          left.times do
            new_commit_edit_new_file_on_branch(repository_rugged, 'encoding/CHANGELOG', 'left-branch', 'some more content for a', 'some stuff')
          end

          right.times do
            new_commit_edit_new_file_on_branch(repository_rugged, 'encoding/CHANGELOG', 'right-branch', 'some more content for b', 'some stuff')
          end
        end

        after do
          repository.delete_branch('left-branch')
          repository.delete_branch('right-branch')
        end

        it 'returns the correct count bounding at max_count' do
          branch_a_sha = repository_rugged.branches['left-branch'].target.oid
          branch_b_sha = repository_rugged.branches['right-branch'].target.oid

          results = repository.diverging_commit_count(branch_a_sha, branch_b_sha, max_count: max_count)

          expect(results[0] + results[1]).to eq(max_count)
        end
      end
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::CommitService, :diverging_commit_count do
      subject { repository.diverging_commit_count('master', 'master', max_count: 1000) }
    end
  end

  describe '#has_local_branches?' do
    context 'check for local branches' do
      it { expect(repository.has_local_branches?).to eq(true) }

      context 'mutable' do
        let(:repository) { mutable_repository }

        after do
          ensure_seeds
        end

        it 'returns false when there are no branches' do
          # Sanity check
          expect(repository.has_local_branches?).to eq(true)

          FileUtils.rm_rf(File.join(repository_path, 'packed-refs'))
          heads_dir = File.join(repository_path, 'refs/heads')
          FileUtils.rm_rf(heads_dir)
          FileUtils.mkdir_p(heads_dir)

          repository.expire_has_local_branches_cache
          expect(repository.has_local_branches?).to eq(false)
        end
      end

      context 'memoizes the value' do
        it 'returns true' do
          expect(repository).to receive(:uncached_has_local_branches?).once.and_call_original

          2.times do
            expect(repository.has_local_branches?).to eq(true)
          end
        end
      end
    end
  end

  describe '#delete_refs' do
    let(:repository) { mutable_repository }

    after do
      ensure_seeds
    end

    it 'deletes the ref' do
      repository.delete_refs('refs/heads/feature')

      expect(repository_rugged.references['refs/heads/feature']).to be_nil
    end

    it 'deletes all refs' do
      refs = %w[refs/heads/wip refs/tags/v1.1.0]
      repository.delete_refs(*refs)

      refs.each do |ref|
        expect(repository_rugged.references[ref]).to be_nil
      end
    end

    it 'does not fail when deleting an empty list of refs' do
      expect { repository.delete_refs(*[]) }.not_to raise_error
    end

    it 'raises an error if it failed' do
      expect { repository.delete_refs('refs\heads\fix') }.to raise_error(Gitlab::Git::Repository::GitError)
    end
  end

  describe '#branch_names_contains_sha' do
    let(:head_id) { repository_rugged.head.target.oid }
    let(:new_branch) { head_id }
    let(:utf8_branch) { 'branch-é' }

    before do
      repository.create_branch(new_branch)
      repository.create_branch(utf8_branch)
    end

    after do
      repository.delete_branch(new_branch)
      repository.delete_branch(utf8_branch)
    end

    it 'displays that branch' do
      expect(repository.branch_names_contains_sha(head_id)).to include('master', new_branch, utf8_branch)
    end
  end

  describe "#refs_hash" do
    subject { repository.refs_hash }

    it "has as many entries as branches and tags" do
      expected_refs = SeedRepo::Repo::BRANCHES + SeedRepo::Repo::TAGS
      # We flatten in case a commit is pointed at by more than one branch and/or tag
      expect(subject.values.flatten.size).to eq(expected_refs.size)
    end

    it 'has valid commit ids as keys' do
      expect(subject.keys).to all( match(Commit::COMMIT_SHA_PATTERN) )
    end

    it 'does not error when dereferenced_target is nil' do
      blob_id = repository.blob_at('master', 'README.md').id
      repository_rugged.tags.create("refs/tags/blob-tag", blob_id)

      expect { subject }.not_to raise_error
    end
  end

  describe '#fetch_remote' do
    it 'delegates to the gitaly RepositoryService' do
      ssh_auth = double(:ssh_auth)
      expected_opts = {
        ssh_auth: ssh_auth,
        forced: true,
        no_tags: true,
        timeout: described_class::GITLAB_PROJECTS_TIMEOUT,
        prune: false,
        check_tags_changed: false,
        url: nil,
        refmap: nil
      }

      expect(repository.gitaly_repository_client).to receive(:fetch_remote).with('remote-name', expected_opts)

      repository.fetch_remote('remote-name', ssh_auth: ssh_auth, forced: true, no_tags: true, prune: false, check_tags_changed: false)
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :fetch_remote do
      subject { repository.fetch_remote('remote-name') }
    end
  end

  describe '#search_files_by_content' do
    let(:repository) { mutable_repository }
    let(:repository_rugged) { mutable_repository_rugged }
    let(:ref) { 'search-files-by-content-branch' }
    let(:content) { 'foobarbazmepmep' }

    before do
      repository.create_branch(ref)
      new_commit_edit_new_file_on_branch(repository_rugged, 'encoding/CHANGELOG', ref, 'committing something', content)
      new_commit_edit_new_file_on_branch(repository_rugged, 'anotherfile', ref, 'committing something', content)
    end

    after do
      ensure_seeds
    end

    subject do
      repository.search_files_by_content(content, ref)
    end

    it 'has 2 items' do
      expect(subject.size).to eq(2)
    end

    it 'has the correct matching line' do
      expect(subject).to contain_exactly("#{ref}:encoding/CHANGELOG\u00001\u0000#{content}\n",
                                         "#{ref}:anotherfile\u00001\u0000#{content}\n")
    end
  end

  describe '#search_files_by_regexp' do
    let(:ref) { 'master' }

    subject(:result) { mutable_repository.search_files_by_regexp(filter, ref) }

    context 'when sending a valid regexp' do
      let(:filter) { 'files\/.*\/.*\.rb' }

      it 'returns matched files' do
        expect(result).to contain_exactly('files/links/regex.rb',
                                          'files/ruby/popen.rb',
                                          'files/ruby/regex.rb',
                                          'files/ruby/version_info.rb')
      end
    end

    context 'when sending an ivalid regexp' do
      let(:filter) { '*.rb' }

      it 'raises error' do
        expect { result }.to raise_error(GRPC::InvalidArgument,
                                         /missing argument to repetition operator: `*`/)
      end
    end

    context "when the ref doesn't exist" do
      let(:filter) { 'files\/.*\/.*\.rb' }
      let(:ref) { 'non-existing-branch' }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end
  end

  describe '#find_remote_root_ref' do
    it 'gets the remote root ref from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .to receive(:find_remote_root_ref).and_call_original

      expect(repository.find_remote_root_ref('origin', SeedHelper::GITLAB_GIT_TEST_REPO_URL)).to eq 'master'
    end

    it 'returns UTF-8' do
      expect(repository.find_remote_root_ref('origin', SeedHelper::GITLAB_GIT_TEST_REPO_URL)).to be_utf8
    end

    it 'returns nil when remote name is nil' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .not_to receive(:find_remote_root_ref)

      expect(repository.find_remote_root_ref(nil, nil)).to be_nil
    end

    it 'returns nil when remote name is empty' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .not_to receive(:find_remote_root_ref)

      expect(repository.find_remote_root_ref('', '')).to be_nil
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RemoteService, :find_remote_root_ref do
      subject { repository.find_remote_root_ref('origin', SeedHelper::GITLAB_GIT_TEST_REPO_URL) }
    end
  end

  describe "#log" do
    shared_examples 'repository log' do
      let(:commit_with_old_name) do
        Gitlab::Git::Commit.find(repository, @commit_with_old_name_id)
      end

      let(:commit_with_new_name) do
        Gitlab::Git::Commit.find(repository, @commit_with_new_name_id)
      end

      let(:rename_commit) do
        Gitlab::Git::Commit.find(repository, @rename_commit_id)
      end

      before do
        # Add new commits so that there's a renamed file in the commit history
        @commit_with_old_name_id = new_commit_edit_old_file(repository_rugged).oid
        @rename_commit_id = new_commit_move_file(repository_rugged).oid
        @commit_with_new_name_id = new_commit_edit_new_file(repository_rugged, "encoding/CHANGELOG", "Edit encoding/CHANGELOG", "I'm a new changelog with different text").oid
      end

      after do
        # Erase our commits so other tests get the original repo
        repository_rugged.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
      end

      context "where 'follow' == true" do
        let(:options) { { ref: "master", follow: true } }

        context "and 'path' is a directory" do
          it "does not follow renames" do
            log_commits = repository.log(options.merge(path: "encoding"))

            aggregate_failures do
              expect(log_commits).to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).not_to include(commit_with_old_name)
            end
          end
        end

        context "and 'path' is a file that matches the new filename" do
          context 'without offset' do
            it "follows renames" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG"))

              aggregate_failures do
                expect(log_commits).to include(commit_with_new_name)
                expect(log_commits).to include(rename_commit)
                expect(log_commits).to include(commit_with_old_name)
              end
            end
          end

          context 'with offset=1' do
            it "follows renames and skip the latest commit" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1))

              aggregate_failures do
                expect(log_commits).not_to include(commit_with_new_name)
                expect(log_commits).to include(rename_commit)
                expect(log_commits).to include(commit_with_old_name)
              end
            end
          end

          context 'with offset=1', 'and limit=1' do
            it "follows renames, skip the latest commit and return only one commit" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 1))

              expect(log_commits).to contain_exactly(rename_commit)
            end
          end

          context 'with offset=1', 'and limit=2' do
            it "follows renames, skip the latest commit and return only two commits" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 1, limit: 2))

              aggregate_failures do
                expect(log_commits).to contain_exactly(rename_commit, commit_with_old_name)
              end
            end
          end

          context 'with offset=2' do
            it "follows renames and skip the latest commit" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2))

              aggregate_failures do
                expect(log_commits).not_to include(commit_with_new_name)
                expect(log_commits).not_to include(rename_commit)
                expect(log_commits).to include(commit_with_old_name)
              end
            end
          end

          context 'with offset=2', 'and limit=1' do
            it "follows renames, skip the two latest commit and return only one commit" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 1))

              expect(log_commits).to contain_exactly(commit_with_old_name)
            end
          end

          context 'with offset=2', 'and limit=2' do
            it "follows renames, skip the two latest commit and return only one commit" do
              log_commits = repository.log(options.merge(path: "encoding/CHANGELOG", offset: 2, limit: 2))

              aggregate_failures do
                expect(log_commits).not_to include(commit_with_new_name)
                expect(log_commits).not_to include(rename_commit)
                expect(log_commits).to include(commit_with_old_name)
              end
            end
          end
        end

        context "and 'path' is a file that matches the old filename" do
          it "does not follow renames" do
            log_commits = repository.log(options.merge(path: "CHANGELOG"))

            aggregate_failures do
              expect(log_commits).not_to include(commit_with_new_name)
              expect(log_commits).to include(rename_commit)
              expect(log_commits).to include(commit_with_old_name)
            end
          end
        end

        context "unknown ref" do
          it "returns an empty array" do
            log_commits = repository.log(options.merge(ref: 'unknown'))

            expect(log_commits).to eq([])
          end
        end
      end

      context "where 'follow' == false" do
        options = { follow: false }

        context "and 'path' is a directory" do
          let(:log_commits) do
            repository.log(options.merge(path: "encoding"))
          end

          it "does not follow renames" do
            expect(log_commits).to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).not_to include(commit_with_old_name)
          end
        end

        context "and 'path' is a file that matches the new filename" do
          let(:log_commits) do
            repository.log(options.merge(path: "encoding/CHANGELOG"))
          end

          it "does not follow renames" do
            expect(log_commits).to include(commit_with_new_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).not_to include(commit_with_old_name)
          end
        end

        context "and 'path' is a file that matches the old filename" do
          let(:log_commits) do
            repository.log(options.merge(path: "CHANGELOG"))
          end

          it "does not follow renames" do
            expect(log_commits).to include(commit_with_old_name)
            expect(log_commits).to include(rename_commit)
            expect(log_commits).not_to include(commit_with_new_name)
          end
        end

        context "and 'path' includes a directory that used to be a file" do
          let(:log_commits) do
            repository.log(options.merge(ref: "refs/heads/fix-blob-path", path: "files/testdir/file.txt"))
          end

          it "returns a list of commits" do
            expect(log_commits.size).to eq(1)
          end
        end
      end

      context "where provides 'after' timestamp" do
        options = { after: Time.iso8601('2014-03-03T20:15:01+00:00') }

        it "returns commits on or after that timestamp" do
          commits = repository.log(options)

          expect(commits.size).to be > 0
          expect(commits).to satisfy do |commits|
            commits.all? { |commit| commit.committed_date >= options[:after] }
          end
        end
      end

      context "where provides 'before' timestamp" do
        options = { before: Time.iso8601('2014-03-03T20:15:01+00:00') }

        it "returns commits on or before that timestamp" do
          commits = repository.log(options)

          expect(commits.size).to be > 0
          expect(commits).to satisfy do |commits|
            commits.all? { |commit| commit.committed_date <= options[:before] }
          end
        end
      end

      context 'when multiple paths are provided' do
        let(:options) { { ref: 'master', path: ['PROCESS.md', 'README.md'] } }

        def commit_files(commit)
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            commit.deltas.flat_map do |delta|
              [delta.old_path, delta.new_path].uniq.compact
            end
          end
        end

        it 'only returns commits matching at least one path' do
          commits = repository.log(options)

          expect(commits.size).to be > 0
          expect(commits).to satisfy do |commits|
            commits.none? { |commit| (commit_files(commit) & options[:path]).empty? }
          end
        end
      end

      context 'limit validation' do
        where(:limit) do
          [0, nil, '', 'foo']
        end

        with_them do
          it { expect { repository.log(limit: limit) }.to raise_error(ArgumentError) }
        end
      end

      context 'with all' do
        it 'returns a list of commits' do
          commits = repository.log({ all: true, limit: 50 })

          expect(commits.size).to eq(37)
        end
      end
    end

    context 'when Gitaly find_commits feature is enabled' do
      it_behaves_like 'repository log'
    end
  end

  describe '#blobs' do
    let_it_be(:commit_oid) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }

    shared_examples 'a blob enumeration' do
      it 'enumerates blobs' do
        blobs = repository.blobs(revisions).to_a

        expect(blobs.size).to eq(expected_blobs)
        blobs.each do |blob|
          expect(blob.data).to be_empty
          expect(blob.id.size).to be(40)
        end
      end
    end

    context 'single revision' do
      let(:revisions) { [commit_oid] }
      let(:expected_blobs) { 53 }

      it_behaves_like 'a blob enumeration'
    end

    context 'multiple revisions' do
      let(:revisions) { ["^#{commit_oid}~", commit_oid] }
      let(:expected_blobs) { 1 }

      it_behaves_like 'a blob enumeration'
    end

    context 'pseudo revisions' do
      let(:revisions) { ['master', '--not', '--all'] }
      let(:expected_blobs) { 0 }

      it_behaves_like 'a blob enumeration'
    end

    context 'blank revisions' do
      let(:revisions) { [::Gitlab::Git::BLANK_SHA] }
      let(:expected_blobs) { 0 }

      before do
        expect_any_instance_of(Gitlab::GitalyClient::BlobService)
          .not_to receive(:list_blobs)
      end

      it_behaves_like 'a blob enumeration'
    end

    context 'partially blank revisions' do
      let(:revisions) { [::Gitlab::Git::BLANK_SHA, commit_oid] }
      let(:expected_blobs) { 53 }

      before do
        expect_next_instance_of(Gitlab::GitalyClient::BlobService) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with([commit_oid], kind_of(Hash))
            .and_call_original
        end
      end

      it_behaves_like 'a blob enumeration'
    end
  end

  describe '#new_commits' do
    let(:repository) { mutable_repository }
    let(:new_commit) do
      author = { name: 'Test User', email: 'mail@example.com', time: Time.now }

      Rugged::Commit.create(repository_rugged,
                            author: author,
                            committer: author,
                            message: "Message",
                            parents: [],
                            tree: "4b825dc642cb6eb9a060e54bf8d69288fbee4904")
    end

    let(:expected_commits) { 1 }
    let(:revisions) { [new_commit] }

    shared_examples 'an enumeration of new commits' do
      it 'enumerates commits' do
        commits = repository.new_commits(revisions).to_a

        expect(commits.size).to eq(expected_commits)
        commits.each do |commit|
          expect(commit.id).to eq(new_commit)
          expect(commit.message).to eq("Message")
        end
      end
    end

    context 'with list_commits disabled' do
      before do
        stub_feature_flags(list_commits: false)

        expect_next_instance_of(Gitlab::GitalyClient::RefService) do |service|
          expect(service)
            .to receive(:list_new_commits)
            .with(new_commit)
            .and_call_original
        end
      end

      it_behaves_like 'an enumeration of new commits'
    end

    context 'with list_commits enabled' do
      before do
        expect_next_instance_of(Gitlab::GitalyClient::CommitService) do |service|
          expect(service)
            .to receive(:list_commits)
            .with([new_commit, '--not', '--all'])
            .and_call_original
        end
      end

      it_behaves_like 'an enumeration of new commits'
    end
  end

  describe '#count_commits_between' do
    subject { repository.count_commits_between('feature', 'master') }

    it { is_expected.to eq(17) }
  end

  describe '#raw_changes_between' do
    let(:old_rev) { }
    let(:new_rev) { }
    let(:changes) { repository.raw_changes_between(old_rev, new_rev) }

    context 'initial commit' do
      let(:old_rev) { Gitlab::Git::BLANK_SHA }
      let(:new_rev) { '1a0b36b3cdad1d2ee32457c102a8c0b7056fa863' }

      it 'returns the changes' do
        expect(changes).to be_present
        expect(changes.size).to eq(3)
      end
    end

    context 'with an invalid rev' do
      let(:old_rev) { 'foo' }
      let(:new_rev) { 'bar' }

      it 'returns an error' do
        expect { changes }.to raise_error(Gitlab::Git::Repository::GitError)
      end
    end

    context 'with valid revs' do
      let(:old_rev) { 'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6' }
      let(:new_rev) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }

      it 'returns the changes' do
        expect(changes.size).to eq(9)
        expect(changes.first.operation).to eq(:modified)
        expect(changes.first.new_path).to eq('.gitmodules')
        expect(changes.last.operation).to eq(:added)
        expect(changes.last.new_path).to eq('files/lfs/picture-invalid.png')
      end
    end
  end

  describe '#merge_base' do
    where(:from, :to, :result) do
      '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' | '40f4a7a617393735a95a0bb67b08385bc1e7c66d' | '570e7b2abdd848b95f2f578043fc23bd6f6fd24d'
      '40f4a7a617393735a95a0bb67b08385bc1e7c66d' | '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' | '570e7b2abdd848b95f2f578043fc23bd6f6fd24d'
      '40f4a7a617393735a95a0bb67b08385bc1e7c66d' | 'foobar' | nil
      'foobar' | '40f4a7a617393735a95a0bb67b08385bc1e7c66d' | nil
    end

    with_them do
      it { expect(repository.merge_base(from, to)).to eq(result) }
    end
  end

  describe '#count_commits' do
    describe 'extended commit counting' do
      context 'with after timestamp' do
        it 'returns the number of commits after timestamp' do
          options = { ref: 'master', after: Time.iso8601('2013-03-03T20:15:01+00:00') }

          expect(repository.count_commits(options)).to eq(25)
        end
      end

      context 'with before timestamp' do
        it 'returns the number of commits before timestamp' do
          options = { ref: 'feature', before: Time.iso8601('2015-03-03T20:15:01+00:00') }

          expect(repository.count_commits(options)).to eq(9)
        end
      end

      context 'with max_count' do
        it 'returns the number of commits with path' do
          options = { ref: 'master', max_count: 5 }

          expect(repository.count_commits(options)).to eq(5)
        end
      end

      context 'with path' do
        it 'returns the number of commits with path' do
          options = { ref: 'master', path: 'encoding' }

          expect(repository.count_commits(options)).to eq(2)
        end
      end

      context 'with option :from and option :to' do
        it 'returns the number of commits ahead for fix-mode..fix-blob-path' do
          options = { from: 'fix-mode', to: 'fix-blob-path' }

          expect(repository.count_commits(options)).to eq(2)
        end

        it 'returns the number of commits ahead for fix-blob-path..fix-mode' do
          options = { from: 'fix-blob-path', to: 'fix-mode' }

          expect(repository.count_commits(options)).to eq(1)
        end

        context 'with option :left_right' do
          it 'returns the number of commits for fix-mode...fix-blob-path' do
            options = { from: 'fix-mode', to: 'fix-blob-path', left_right: true }

            expect(repository.count_commits(options)).to eq([1, 2])
          end

          context 'with max_count' do
            it 'returns the number of commits with path' do
              options = { from: 'fix-mode', to: 'fix-blob-path', left_right: true, max_count: 1 }

              expect(repository.count_commits(options)).to eq([1, 1])
            end
          end
        end
      end

      context 'with max_count' do
        it 'returns the number of commits up to the passed limit' do
          options = { ref: 'master', max_count: 10, after: Time.iso8601('2013-03-03T20:15:01+00:00') }

          expect(repository.count_commits(options)).to eq(10)
        end
      end

      context "with all" do
        it "returns the number of commits in the whole repository" do
          options = { all: true }

          expect(repository.count_commits(options)).to eq(34)
        end
      end

      context 'without all or ref being specified' do
        it "raises an ArgumentError" do
          expect { repository.count_commits({}) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#find_branch' do
    it 'returns a Branch for master' do
      branch = repository.find_branch('master')

      expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
      expect(branch.name).to eq('master')
    end

    it 'handles non-existent branch' do
      branch = repository.find_branch('this-is-garbage')

      expect(branch).to eq(nil)
    end
  end

  describe '#ref_name_for_sha' do
    let(:ref_path) { 'refs/heads' }
    let(:sha) { repository.find_branch('master').dereferenced_target.id }
    let(:ref_name) { 'refs/heads/master' }

    it 'returns the ref name for the given sha' do
      expect(repository.ref_name_for_sha(ref_path, sha)).to eq(ref_name)
    end

    it "returns an empty name if the ref doesn't exist" do
      expect(repository.ref_name_for_sha(ref_path, "000000")).to eq("")
    end

    it "raise an exception if the ref is empty" do
      expect { repository.ref_name_for_sha(ref_path, "") }.to raise_error(ArgumentError)
    end

    it "raise an exception if the ref is nil" do
      expect { repository.ref_name_for_sha(ref_path, nil) }.to raise_error(ArgumentError)
    end
  end

  describe '#branches' do
    subject { repository.branches }

    context 'with local and remote branches' do
      let(:repository) { mutable_repository }

      before do
        create_remote_branch('joe', 'remote_branch', 'master')
        repository.create_branch('local_branch')
      end

      after do
        ensure_seeds
      end

      it 'returns the local and remote branches' do
        expect(subject.any? { |b| b.name == 'joe/remote_branch' }).to eq(true)
        expect(subject.any? { |b| b.name == 'local_branch' }).to eq(true)
      end
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :branches
  end

  describe '#branch_count' do
    it 'returns the number of branches' do
      expect(repository.branch_count).to eq(11)
    end

    context 'with local and remote branches' do
      let(:repository) { mutable_repository }

      before do
        create_remote_branch('joe', 'remote_branch', 'master')
        repository.create_branch('local_branch')
      end

      after do
        ensure_seeds
      end

      it 'returns the count of local branches' do
        expect(repository.branch_count).to eq(repository.local_branches.count)
      end

      context 'with Gitaly disabled' do
        before do
          allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)
        end

        it 'returns the count of local branches' do
          expect(repository.branch_count).to eq(repository.local_branches.count)
        end
      end
    end
  end

  describe '#merged_branch_names' do
    context 'when branch names are passed' do
      it 'only returns the names we are asking' do
        names = repository.merged_branch_names(%w[merge-test])

        expect(names).to contain_exactly('merge-test')
      end

      it 'does not return unmerged branch names' do
        names = repository.merged_branch_names(%w[feature])

        expect(names).to be_empty
      end
    end

    context 'when no root ref is available' do
      it 'returns empty list' do
        project = create(:project, :empty_repo)

        names = project.repository.merged_branch_names(%w[feature])

        expect(names).to be_empty
      end
    end

    context 'when no branch names are specified' do
      before do
        repository.create_branch('identical')
      end

      after do
        ensure_seeds
      end

      it 'returns all merged branch names except for identical one' do
        names = repository.merged_branch_names

        expect(names).to include('merge-test')
        expect(names).to include('fix-mode')
        expect(names).not_to include('feature')
        expect(names).not_to include('identical')
      end
    end
  end

  describe '#diff_stats' do
    let(:left_commit_id) { 'feature' }
    let(:right_commit_id) { 'master' }

    it 'returns a DiffStatsCollection' do
      collection = repository.diff_stats(left_commit_id, right_commit_id)

      expect(collection).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(collection).to be_a(Enumerable)
    end

    it 'yields Gitaly::DiffStats objects' do
      collection = repository.diff_stats(left_commit_id, right_commit_id)

      expect(collection.to_a).to all(be_a(Gitaly::DiffStats))
    end

    it 'returns no Gitaly::DiffStats when SHAs are invalid' do
      collection = repository.diff_stats('foo', 'bar')

      expect(collection).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end

    it 'returns no Gitaly::DiffStats when there is a nil SHA' do
      expect_any_instance_of(Gitlab::GitalyClient::CommitService)
        .not_to receive(:diff_stats)

      collection = repository.diff_stats(nil, 'master')

      expect(collection).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end

    it 'returns no Gitaly::DiffStats when there is a BLANK_SHA' do
      expect_any_instance_of(Gitlab::GitalyClient::CommitService)
        .not_to receive(:diff_stats)

      collection = repository.diff_stats(Gitlab::Git::BLANK_SHA, 'master')

      expect(collection).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end
  end

  describe '#find_changed_paths' do
    let(:commit_1) { 'fa1b1e6c004a68b7d8763b86455da9e6b23e36d6' }
    let(:commit_2) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }
    let(:commit_3) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    let(:commit_1_files) do
      [
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "files/executables/ls"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "files/executables/touch"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "files/links/regex.rb"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "files/links/ruby-style-guide.md"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "files/links/touch"),
        Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: ".gitmodules"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "deeper/nested/six"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "nested/six")
      ]
    end

    let(:commit_2_files) do
      [Gitlab::Git::ChangedPath.new(status: :ADDED, path: "bin/executable")]
    end

    let(:commit_3_files) do
      [
        Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: ".gitmodules"),
        Gitlab::Git::ChangedPath.new(status: :ADDED, path: "gitlab-shell")
      ]
    end

    it 'returns a list of paths' do
      collection = repository.find_changed_paths([commit_1, commit_2, commit_3])

      expect(collection).to be_a(Enumerable)
      expect(collection.as_json).to eq((commit_1_files + commit_2_files + commit_3_files).as_json)
    end

    it 'returns no paths when SHAs are invalid' do
      collection = repository.find_changed_paths(['invalid', commit_1])

      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end

    it 'returns a list of paths even when containing a blank ref' do
      collection = repository.find_changed_paths([nil, commit_1])

      expect(collection).to be_a(Enumerable)
      expect(collection.as_json).to eq(commit_1_files.as_json)
    end

    it 'returns no paths when the commits are nil' do
      expect_any_instance_of(Gitlab::GitalyClient::CommitService)
        .not_to receive(:find_changed_paths)

      collection = repository.find_changed_paths([nil, nil])

      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end
  end

  describe "#ls_files" do
    let(:master_file_paths) { repository.ls_files("master") }
    let(:utf8_file_paths) { repository.ls_files("ls-files-utf8") }
    let(:not_existed_branch) { repository.ls_files("not_existed_branch") }

    it "read every file paths of master branch" do
      expect(master_file_paths.length).to equal(40)
    end

    it "reads full file paths of master branch" do
      expect(master_file_paths).to include("files/html/500.html")
    end

    it "does not read submodule directory and empty directory of master branch" do
      expect(master_file_paths).not_to include("six")
    end

    it "does not include 'nil'" do
      expect(master_file_paths).not_to include(nil)
    end

    it "returns empty array when not existed branch" do
      expect(not_existed_branch.length).to equal(0)
    end

    it "returns valid utf-8 data" do
      expect(utf8_file_paths.map { |file| file.force_encoding('utf-8') }).to all(be_valid_encoding)
    end
  end

  describe "#copy_gitattributes" do
    let(:attributes_path) { File.join(SEED_STORAGE_PATH, TEST_REPO_PATH, 'info/attributes') }

    after do
      FileUtils.rm_rf(attributes_path) if Dir.exist?(attributes_path)
    end

    it "raises an error with invalid ref" do
      expect { repository.copy_gitattributes("invalid") }.to raise_error(Gitlab::Git::Repository::InvalidRef)
    end

    context 'when forcing encoding issues' do
      let(:branch_name) { "ʕ•ᴥ•ʔ" }

      before do
        repository.create_branch(branch_name)
      end

      after do
        repository.rm_branch(branch_name, user: build(:admin))
      end

      it "doesn't raise with a valid unicode ref" do
        expect { repository.copy_gitattributes(branch_name) }.not_to raise_error

        repository
      end
    end

    context "with no .gitattrbutes" do
      before do
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end
    end

    context "with .gitattrbutes" do
      before do
        repository.copy_gitattributes("gitattributes")
      end

      it "has an info/attributes" do
        expect(File.exist?(attributes_path)).to be_truthy
      end

      it "has the same content in info/attributes as .gitattributes" do
        contents = File.open(attributes_path, "rb") { |f| f.read }
        expect(contents).to eq("*.md binary\n")
      end
    end

    context "with updated .gitattrbutes" do
      before do
        repository.copy_gitattributes("gitattributes")
        repository.copy_gitattributes("gitattributes-updated")
      end

      it "has an info/attributes" do
        expect(File.exist?(attributes_path)).to be_truthy
      end

      it "has the updated content in info/attributes" do
        contents = File.read(attributes_path)
        expect(contents).to eq("*.txt binary\n")
      end
    end

    context "with no .gitattrbutes in HEAD but with previous info/attributes" do
      before do
        repository.copy_gitattributes("gitattributes")
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end
    end
  end

  describe '#gitattribute' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_GITATTRIBUTES_REPO_PATH, '', 'group/project') }

    after do
      ensure_seeds
    end

    it 'returns matching language attribute' do
      expect(repository.gitattribute("custom-highlighting/test.gitlab-custom", 'gitlab-language')).to eq('ruby')
    end

    it 'returns matching language attribute with additional options' do
      expect(repository.gitattribute("custom-highlighting/test.gitlab-cgi", 'gitlab-language')).to eq('erb?parent=json')
    end

    it 'returns nil if nothing matches' do
      expect(repository.gitattribute("report.xslt", 'gitlab-language')).to eq(nil)
    end

    context 'without gitattributes file' do
      let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }

      it 'returns nil' do
        expect(repository.gitattribute("README.md", 'gitlab-language')).to eq(nil)
      end
    end
  end

  describe '#ref_exists?' do
    it 'returns true for an existing tag' do
      expect(repository.ref_exists?('refs/heads/master')).to eq(true)
    end

    it 'returns false for a non-existing tag' do
      expect(repository.ref_exists?('refs/tags/THIS_TAG_DOES_NOT_EXIST')).to eq(false)
    end

    it 'raises an ArgumentError for an empty string' do
      expect { repository.ref_exists?('') }.to raise_error(ArgumentError)
    end

    it 'raises an ArgumentError for an invalid ref' do
      expect { repository.ref_exists?('INVALID') }.to raise_error(ArgumentError)
    end
  end

  describe '#tag_exists?' do
    it 'returns true for an existing tag' do
      tag = repository.tag_names.first

      expect(repository.tag_exists?(tag)).to eq(true)
    end

    it 'returns false for a non-existing tag' do
      expect(repository.tag_exists?('v9000')).to eq(false)
    end
  end

  describe '#branch_exists?' do
    it 'returns true for an existing branch' do
      expect(repository.branch_exists?('master')).to eq(true)
    end

    it 'returns false for a non-existing branch' do
      expect(repository.branch_exists?('kittens')).to eq(false)
    end

    it 'returns false when using an invalid branch name' do
      expect(repository.branch_exists?('.bla')).to eq(false)
    end
  end

  describe '#local_branches' do
    let(:repository) { mutable_repository }

    before do
      create_remote_branch('joe', 'remote_branch', 'master')
      repository.create_branch('local_branch')
    end

    after do
      ensure_seeds
    end

    it 'returns the local branches' do
      expect(repository.local_branches.any? { |branch| branch.name == 'remote_branch' }).to eq(false)
      expect(repository.local_branches.any? { |branch| branch.name == 'local_branch' }).to eq(true)
    end

    it 'returns a Branch with UTF-8 fields' do
      branches = repository.local_branches.to_a
      expect(branches.size).to be > 0
      branches.each do |branch|
        expect(branch.name).to be_utf8
        expect(branch.target).to be_utf8 unless branch.target.nil?
      end
    end

    it 'gets the branches from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:local_branches)
        .and_return([])
      repository.local_branches
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :local_branches do
      subject { repository.local_branches }
    end
  end

  describe '#languages' do
    it 'returns exactly the expected results' do
      languages = repository.languages('4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6')
      expected_languages = [
        { value: 66.63, label: "Ruby", color: "#701516", highlight: "#701516" },
        { value: 22.96, label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a" },
        { value: 7.9, label: "HTML", color: "#e34c26", highlight: "#e34c26" },
        { value: 2.51, label: "CoffeeScript", color: "#244776", highlight: "#244776" }
      ]

      expect(languages.size).to eq(expected_languages.size)

      expected_languages.size.times do |i|
        a = expected_languages[i]
        b = languages[i]

        expect(a.keys.sort).to eq(b.keys.sort)
        expect(a[:value]).to be_within(0.1).of(b[:value])

        non_float_keys = a.keys - [:value]
        expect(a.values_at(*non_float_keys)).to eq(b.values_at(*non_float_keys))
      end
    end

    it "uses the repository's HEAD when no ref is passed" do
      lang = repository.languages.first

      expect(lang[:label]).to eq('Ruby')
    end
  end

  describe '#license_short_name' do
    subject { repository.license_short_name }

    context 'when no license file can be found' do
      let(:project) { create(:project, :repository) }
      let(:repository) { project.repository.raw_repository }

      before do
        project.repository.delete_file(project.owner, 'LICENSE', message: 'remove license', branch_name: 'master')
      end

      it { is_expected.to be_nil }
    end

    context 'when an mit license is found' do
      it { is_expected.to eq('mit') }
    end
  end

  describe '#fetch_source_branch!' do
    let(:local_ref) { 'refs/merge-requests/1/head' }
    let(:source_repository) { mutable_repository }

    after do
      ensure_seeds
    end

    context 'when the branch exists' do
      context 'when the commit does not exist locally' do
        let(:source_branch) { 'new-branch-for-fetch-source-branch' }
        let(:source_path) { File.join(TestEnv.repos_path, source_repository.relative_path) }
        let(:source_rugged) { Rugged::Repository.new(source_path) }
        let(:new_oid) { new_commit_edit_old_file(source_rugged).oid }

        before do
          source_rugged.branches.create(source_branch, new_oid)
        end

        it 'writes the ref' do
          expect(repository.fetch_source_branch!(source_repository, source_branch, local_ref)).to eq(true)
          expect(repository.commit(local_ref).sha).to eq(new_oid)
        end
      end

      context 'when the commit exists locally' do
        let(:source_branch) { 'master' }
        let(:expected_oid) { SeedRepo::LastCommit::ID }

        it 'writes the ref' do
          # Sanity check: the commit should already exist
          expect(repository.commit(expected_oid)).not_to be_nil

          expect(repository.fetch_source_branch!(source_repository, source_branch, local_ref)).to eq(true)
          expect(repository.commit(local_ref).sha).to eq(expected_oid)
        end
      end
    end

    context 'when the branch does not exist' do
      let(:source_branch) { 'definitely-not-master' }

      it 'does not write the ref' do
        expect(repository.fetch_source_branch!(source_repository, source_branch, local_ref)).to eq(false)
        expect(repository.commit(local_ref)).to be_nil
      end
    end
  end

  describe '#rm_branch' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository.raw }
    let(:branch_name) { "to-be-deleted-soon" }

    before do
      project.add_developer(user)
      repository.create_branch(branch_name)
    end

    it "removes the branch from the repo" do
      repository.rm_branch(branch_name, user: user)

      expect(repository_rugged.branches[branch_name]).to be_nil
    end
  end

  describe '#write_ref' do
    context 'validations' do
      using RSpec::Parameterized::TableSyntax

      where(:ref_path, :ref) do
        'foo bar' | '123'
        'foobar'  | "12\x003"
      end

      with_them do
        it 'raises ArgumentError' do
          expect { repository.write_ref(ref_path, ref) }.to raise_error(ArgumentError)
        end
      end
    end

    it 'writes the HEAD' do
      repository.write_ref('HEAD', 'refs/heads/feature')

      expect(repository.commit('HEAD')).to eq(repository.commit('feature'))
      expect(repository.root_ref).to eq('feature')
    end

    it 'writes other refs' do
      repository.write_ref('refs/heads/feature', SeedRepo::Commit::ID)

      expect(repository.commit('feature').sha).to eq(SeedRepo::Commit::ID)
    end
  end

  describe '#write_config' do
    before do
      repository_rugged.config["gitlab.fullpath"] = repository_path
    end

    context 'is given a path' do
      it 'writes it to disk' do
        repository.write_config(full_path: "not-the/real-path.git")

        config = File.read(File.join(repository_path, "config"))

        expect(config).to include("[gitlab]")
        expect(config).to include("fullpath = not-the/real-path.git")
      end
    end

    context 'it is given an empty path' do
      it 'does not write it to disk' do
        repository.write_config(full_path: "")

        config = File.read(File.join(repository_path, "config"))

        expect(config).to include("[gitlab]")
        expect(config).to include("fullpath = #{repository_path}")
      end
    end

    context 'repository does not exist' do
      it 'raises NoRepository and does not call Gitaly WriteConfig' do
        repository = Gitlab::Git::Repository.new('default', 'does/not/exist.git', '', 'group/project')

        expect(repository.gitaly_repository_client).not_to receive(:write_config)

        expect do
          repository.write_config(full_path: 'foo/bar.git')
        end.to raise_error(Gitlab::Git::Repository::NoRepository)
      end
    end
  end

  describe '#set_config' do
    let(:repository) { mutable_repository }
    let(:entries) do
      {
        'test.foo1' => 'bla bla',
        'test.foo2' => 1234,
        'test.foo3' => true
      }
    end

    it 'can set config settings' do
      expect(repository.set_config(entries)).to be_nil

      expect(repository_rugged.config['test.foo1']).to eq('bla bla')
      expect(repository_rugged.config['test.foo2']).to eq('1234')
      expect(repository_rugged.config['test.foo3']).to eq('true')
    end

    after do
      entries.keys.each { |k| repository_rugged.config.delete(k) }
    end
  end

  describe '#delete_config' do
    let(:repository) { mutable_repository }
    let(:entries) do
      {
        'test.foo1' => 'bla bla',
        'test.foo2' => 1234,
        'test.foo3' => true
      }
    end

    it 'can delete config settings' do
      entries.each do |key, value|
        repository_rugged.config[key] = value
      end

      expect(repository.delete_config(*%w[does.not.exist test.foo1 test.foo2])).to be_nil

      # Workaround for https://github.com/libgit2/rugged/issues/785: If
      # Gitaly changes .gitconfig while Rugged has the file loaded
      # Rugged::Repository#each_key will report stale values unless a
      # lookup is done first.
      expect(repository_rugged.config['test.foo1']).to be_nil
      config_keys = repository_rugged.config.each_key.to_a
      expect(config_keys).not_to include('test.foo1')
      expect(config_keys).not_to include('test.foo2')
    end
  end

  describe '#merge_to_ref' do
    let(:repository) { mutable_repository }
    let(:branch_head) { '6d394385cf567f80a8fd85055db1ab4c5295806f' }
    let(:left_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:right_branch) { 'test-master' }
    let(:first_parent_ref) { 'refs/heads/test-master' }
    let(:target_ref) { 'refs/merge-requests/999/merge' }

    before do
      repository.create_branch(right_branch, branch_head) unless repository.ref_exists?(first_parent_ref)
    end

    def merge_to_ref
      repository.merge_to_ref(user,
          source_sha: left_sha, branch: right_branch, target_ref: target_ref,
          message: 'Merge message', first_parent_ref: first_parent_ref)
    end

    it 'generates a commit in the target_ref' do
      expect(repository.ref_exists?(target_ref)).to be(false)

      commit_sha = merge_to_ref
      ref_head = repository.commit(target_ref)

      expect(commit_sha).to be_present
      expect(repository.ref_exists?(target_ref)).to be(true)
      expect(ref_head.id).to eq(commit_sha)
    end

    it 'does not change the right branch HEAD' do
      expect { merge_to_ref }.not_to change { repository.commit(first_parent_ref).sha }
    end
  end

  describe '#merge' do
    let(:repository) { mutable_repository }
    let(:source_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
    let(:target_branch) { 'test-merge-target-branch' }

    before do
      repository.create_branch(target_branch, '6d394385cf567f80a8fd85055db1ab4c5295806f')
    end

    after do
      ensure_seeds
    end

    it 'can perform a merge' do
      merge_commit_id = nil
      result = repository.merge(user, source_sha, target_branch, 'Test merge') do |commit_id|
        merge_commit_id = commit_id
      end

      expect(result.newrev).to eq(merge_commit_id)
      expect(result.repo_created).to eq(false)
      expect(result.branch_created).to eq(false)
    end

    it 'returns nil if there was a concurrent branch update' do
      concurrent_update_id = '33f3729a45c02fc67d00adb1b8bca394b0e761d9'
      result = repository.merge(user, source_sha, target_branch, 'Test merge') do
        # This ref update should make the merge fail
        repository.write_ref(Gitlab::Git::BRANCH_REF_PREFIX + target_branch, concurrent_update_id)
      end

      # This 'nil' signals that the merge was not applied
      expect(result).to be_nil

      # Our concurrent ref update should not have been undone
      expect(repository.find_branch(target_branch).target).to eq(concurrent_update_id)
    end
  end

  describe '#ff_merge' do
    let(:repository) { mutable_repository }
    let(:branch_head) { '6d394385cf567f80a8fd85055db1ab4c5295806f' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:target_branch) { 'test-ff-target-branch' }

    before do
      repository.create_branch(target_branch, branch_head)
    end

    after do
      ensure_seeds
    end

    subject { repository.ff_merge(user, source_sha, target_branch) }

    shared_examples '#ff_merge' do
      it 'performs a ff_merge' do
        expect(subject.newrev).to eq(source_sha)
        expect(subject.repo_created).to be(false)
        expect(subject.branch_created).to be(false)

        expect(repository.commit(target_branch).id).to eq(source_sha)
      end

      context 'with a non-existing target branch' do
        subject { repository.ff_merge(user, source_sha, 'this-isnt-real') }

        it 'throws an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'with a non-existing source commit' do
        let(:source_sha) { 'f001' }

        it 'throws an ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when the source sha is not a descendant of the branch head' do
        let(:source_sha) { '1a0b36b3cdad1d2ee32457c102a8c0b7056fa863' }

        it "doesn't perform the ff_merge" do
          expect { subject }.to raise_error(Gitlab::Git::CommitError)

          expect(repository.commit(target_branch).id).to eq(branch_head)
        end
      end
    end

    it "calls Gitaly's OperationService" do
      expect_any_instance_of(Gitlab::GitalyClient::OperationService)
        .to receive(:user_ff_branch).with(user, source_sha, target_branch)
        .and_return(nil)

      subject
    end

    it_behaves_like '#ff_merge'
  end

  describe '#delete_all_refs_except' do
    let(:repository) { mutable_repository }

    before do
      repository.write_ref("refs/delete/a", "0b4bc9a49b562e85de7cc9e834518ea6828729b9")
      repository.write_ref("refs/also-delete/b", "12d65c8dd2b2676fa3ac47d955accc085a37a9c1")
      repository.write_ref("refs/keep/c", "6473c90867124755509e100d0d35ebdc85a0b6ae")
      repository.write_ref("refs/also-keep/d", "0b4bc9a49b562e85de7cc9e834518ea6828729b9")
    end

    after do
      ensure_seeds
    end

    it 'deletes all refs except those with the specified prefixes' do
      repository.delete_all_refs_except(%w(refs/keep refs/also-keep refs/heads))
      expect(repository.ref_exists?("refs/delete/a")).to be(false)
      expect(repository.ref_exists?("refs/also-delete/b")).to be(false)
      expect(repository.ref_exists?("refs/keep/c")).to be(true)
      expect(repository.ref_exists?("refs/also-keep/d")).to be(true)
      expect(repository.ref_exists?("refs/heads/master")).to be(true)
    end
  end

  describe '#bundle_to_disk' do
    let(:save_path) { File.join(Dir.tmpdir, "repo-#{SecureRandom.hex}.bundle") }

    after do
      FileUtils.rm_rf(save_path)
    end

    it 'saves a bundle to disk' do
      repository.bundle_to_disk(save_path)

      success = system(
        *%W(#{Gitlab.config.git.bin_path} -C #{repository_path} bundle verify #{save_path}),
        [:out, :err] => '/dev/null'
      )
      expect(success).to be true
    end
  end

  describe '#create_from_bundle' do
    let(:valid_bundle_path) { File.join(Dir.tmpdir, "repo-#{SecureRandom.hex}.bundle") }
    let(:malicious_bundle_path) { Rails.root.join('spec/fixtures/malicious.bundle') }
    let(:project) { create(:project) }
    let(:imported_repo) { project.repository.raw }

    before do
      expect(repository.bundle_to_disk(valid_bundle_path)).to be_truthy
    end

    after do
      FileUtils.rm_rf(valid_bundle_path)
    end

    it 'creates a repo from a bundle file' do
      expect(imported_repo).not_to exist

      result = imported_repo.create_from_bundle(valid_bundle_path)

      expect(result).to be_truthy
      expect(imported_repo).to exist
      expect { imported_repo.fsck }.not_to raise_exception
    end

    it 'raises an error if the bundle is an attempted malicious payload' do
      expect do
        imported_repo.create_from_bundle(malicious_bundle_path)
      end.to raise_error(::Gitlab::Git::BundleFile::InvalidBundleError)
    end
  end

  describe '#compare_source_branch' do
    it 'delegates to Gitlab::Git::CrossRepoComparer' do
      expect_next_instance_of(::Gitlab::Git::CrossRepoComparer) do |instance|
        expect(instance.source_repo).to eq(:source_repository)
        expect(instance.target_repo).to eq(repository)

        expect(instance).to receive(:compare).with('feature', 'master', straight: :straight)
      end

      repository.compare_source_branch('master', :source_repository, 'feature', straight: :straight)
    end
  end

  describe '#checksum' do
    it 'calculates the checksum for non-empty repo' do
      expect(repository.checksum).to eq '51d0a9662681f93e1fee547a6b7ba2bcaf716059'
    end

    it 'returns 0000000000000000000000000000000000000000 for an empty repo' do
      FileUtils.rm_rf(File.join(storage_path, 'empty-repo.git'))

      system(git_env, *%W(#{Gitlab.config.git.bin_path} init --bare empty-repo.git),
             chdir: storage_path,
             out:   '/dev/null',
             err:   '/dev/null')

      empty_repo = described_class.new('default', 'empty-repo.git', '', 'group/empty-repo')

      expect(empty_repo.checksum).to eq '0000000000000000000000000000000000000000'
    end

    it 'raises Gitlab::Git::Repository::InvalidRepository error for non-valid git repo' do
      FileUtils.rm_rf(File.join(storage_path, 'non-valid.git'))

      system(git_env, *%W(#{Gitlab.config.git.bin_path} clone --bare #{TEST_REPO_PATH} non-valid.git),
             chdir: SEED_STORAGE_PATH,
             out: '/dev/null',
             err: '/dev/null')

      File.truncate(File.join(storage_path, 'non-valid.git/HEAD'), 0)

      non_valid = described_class.new('default', 'non-valid.git', '', 'a/non-valid')

      expect { non_valid.checksum }.to raise_error(Gitlab::Git::Repository::InvalidRepository)
    end

    it 'raises Gitlab::Git::Repository::NoRepository error when there is no repo' do
      broken_repo = described_class.new('default', 'a/path.git', '', 'a/path')

      expect { broken_repo.checksum }.to raise_error(Gitlab::Git::Repository::NoRepository)
    end
  end

  describe '#replicas', :praefect do
    it 'gets the replica checksum through praefect' do
      resp = repository.replicas

      expect(resp.replicas).to be_empty
      expect(resp.primary.checksum).to eq(repository.checksum)
    end
  end

  describe '#clean_stale_repository_files' do
    let(:worktree_id) { 'rebase-1' }
    let(:gitlab_worktree_path) { File.join(repository_path, 'gitlab-worktree', worktree_id) }
    let(:admin_dir) { File.join(repository_path, 'worktrees') }

    it 'cleans up the files' do
      create_worktree = %W[git -C #{repository_path} worktree add --detach #{gitlab_worktree_path} master]
      raise 'preparation failed' unless system(*create_worktree, err: '/dev/null')

      FileUtils.touch(gitlab_worktree_path, mtime: Time.now - 8.hours)
      # git rev-list --all will fail in git 2.16 if HEAD is pointing to a non-existent object,
      # but the HEAD must be 40 characters long or git will ignore it.
      File.write(File.join(admin_dir, worktree_id, 'HEAD'), Gitlab::Git::BLANK_SHA)

      expect(rev_list_all).to be(false)
      repository.clean_stale_repository_files

      expect(rev_list_all).to be(true)
      expect(File.exist?(gitlab_worktree_path)).to be_falsey
    end

    def rev_list_all
      system(*%W[git -C #{repository_path} rev-list --all], out: '/dev/null', err: '/dev/null')
    end

    it 'increments a counter upon an error' do
      expect(repository.gitaly_repository_client).to receive(:cleanup).and_raise(Gitlab::Git::CommandError)

      counter = double(:counter)

      expect(counter).to receive(:increment)
      expect(Gitlab::Metrics).to receive(:counter).with(:failed_repository_cleanup_total,
                                                        'Number of failed repository cleanup events').and_return(counter)

      repository.clean_stale_repository_files
    end
  end

  describe '#squash' do
    let(:squash_id) { '1' }
    let(:branch_name) { 'fix' }
    let(:start_sha) { '4b4918a572fa86f9771e5ba40fbd48e1eb03e2c6' }
    let(:end_sha) { '12d65c8dd2b2676fa3ac47d955accc085a37a9c1' }

    subject do
      opts = {
        branch: branch_name,
        start_sha: start_sha,
        end_sha: end_sha,
        author: user,
        message: 'Squash commit message'
      }

      repository.squash(user, squash_id, opts)
    end

    # Should be ported to gitaly-ruby rspec suite https://gitlab.com/gitlab-org/gitaly/issues/1234
    skip 'sparse checkout' do
      let(:expected_files) { %w(files files/js files/js/application.js) }

      it 'checks out only the files in the diff' do
        allow(repository).to receive(:with_worktree).and_wrap_original do |m, *args|
          m.call(*args) do
            worktree_path = args[0]
            files_pattern = File.join(worktree_path, '**', '*')
            expected = expected_files.map do |path|
              File.expand_path(path, worktree_path)
            end

            expect(Dir[files_pattern]).to eq(expected)
          end
        end

        subject
      end

      context 'when the diff contains a rename' do
        let(:end_sha) { new_commit_move_file(repository_rugged).oid }

        after do
          # Erase our commits so other tests get the original repo
          repository_rugged.references.update('refs/heads/master', SeedRepo::LastCommit::ID)
        end

        it 'does not include the renamed file in the sparse checkout' do
          allow(repository).to receive(:with_worktree).and_wrap_original do |m, *args|
            m.call(*args) do
              worktree_path = args[0]
              files_pattern = File.join(worktree_path, '**', '*')

              expect(Dir[files_pattern]).not_to include('CHANGELOG')
              expect(Dir[files_pattern]).not_to include('encoding/CHANGELOG')
            end
          end

          subject
        end
      end
    end

    # Should be ported to gitaly-ruby rspec suite https://gitlab.com/gitlab-org/gitaly/issues/1234
    skip 'with an ASCII-8BIT diff' do
      let(:diff) { "diff --git a/README.md b/README.md\nindex faaf198..43c5edf 100644\n--- a/README.md\n+++ b/README.md\n@@ -1,4 +1,4 @@\n-testme\n+✓ testme\n ======\n \n Sample repo for testing gitlab features\n" }

      it 'applies a ASCII-8BIT diff' do
        allow(repository).to receive(:run_git!).and_call_original
        allow(repository).to receive(:run_git!).with(%W(diff --binary #{start_sha}...#{end_sha})).and_return(diff.force_encoding('ASCII-8BIT'))

        expect(subject).to match(/\h{40}/)
      end
    end

    # Should be ported to gitaly-ruby rspec suite https://gitlab.com/gitlab-org/gitaly/issues/1234
    skip 'with trailing whitespace in an invalid patch' do
      let(:diff) { "diff --git a/README.md b/README.md\nindex faaf198..43c5edf 100644\n--- a/README.md\n+++ b/README.md\n@@ -1,4 +1,4 @@\n-testme\n+   \n ======   \n \n Sample repo for testing gitlab features\n" }

      it 'does not include whitespace warnings in the error' do
        allow(repository).to receive(:run_git!).and_call_original
        allow(repository).to receive(:run_git!).with(%W(diff --binary #{start_sha}...#{end_sha})).and_return(diff.force_encoding('ASCII-8BIT'))

        expect { subject }.to raise_error do |error|
          expect(error).to be_a(described_class::GitError)
          expect(error.message).not_to include('trailing whitespace')
        end
      end
    end
  end

  def create_remote_branch(remote_name, branch_name, source_branch_name)
    source_branch = repository.branches.find { |branch| branch.name == source_branch_name }
    repository_rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", source_branch.dereferenced_target.sha)
  end

  def refs(dir)
    IO.popen(%W[git -C #{dir} for-each-ref], &:read).split("\n").map do |line|
      line.split("\t").last
    end
  end

  describe '#disconnect_alternates' do
    let(:project) { create(:project, :repository) }
    let(:pool_repository) { create(:pool_repository) }
    let(:repository) { project.repository }
    let(:repository_path) { File.join(TestEnv.repos_path, repository.relative_path) }
    let(:object_pool) { pool_repository.object_pool }
    let(:object_pool_path) { File.join(TestEnv.repos_path, object_pool.repository.relative_path) }
    let(:object_pool_rugged) { Rugged::Repository.new(object_pool_path) }

    before do
      object_pool.create # rubocop:disable Rails/SaveBang
    end

    it 'does not raise an error when disconnecting a non-linked repository' do
      expect { repository.disconnect_alternates }.not_to raise_error
    end

    it 'removes the alternates file' do
      object_pool.link(repository)

      alternates_file = File.join(repository_path, "objects", "info", "alternates")
      expect(File.exist?(alternates_file)).to be_truthy

      repository.disconnect_alternates

      expect(File.exist?(alternates_file)).to be_falsey
    end

    it 'can still access objects in the object pool' do
      object_pool.link(repository)
      new_commit = new_commit_edit_old_file(object_pool_rugged)
      expect(repository.commit(new_commit.oid).id).to eq(new_commit.oid)

      repository.disconnect_alternates

      expect(repository.commit(new_commit.oid).id).to eq(new_commit.oid)
    end
  end

  describe '#rename' do
    let(:project) { create(:project, :repository)}
    let(:repository) { project.repository }

    it 'moves the repository' do
      checksum = repository.checksum
      new_relative_path = "rename_test/relative/path"
      renamed_repository = Gitlab::Git::Repository.new(repository.storage, new_relative_path, nil, nil)

      repository.rename(new_relative_path)

      expect(renamed_repository.checksum).to eq(checksum)
      expect(repository.exists?).to be false
    end
  end

  describe '#remove' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }

    it 'removes the repository' do
      expect(repository.exists?).to be true

      repository.remove

      expect(repository.raw_repository.exists?).to be false
    end

    context 'when the repository does not exist' do
      let(:repository) { create(:project).repository }

      it 'is idempotent' do
        expect(repository.exists?).to be false

        repository.remove

        expect(repository.raw_repository.exists?).to be false
      end
    end
  end

  describe '#import_repository' do
    let_it_be(:project) { create(:project) }

    let(:repository) { project.repository }
    let(:url) { 'http://invalid.invalid' }

    it 'raises an error if a relative path is provided' do
      expect { repository.import_repository('/foo') }.to raise_error(ArgumentError, /disk path/)
    end

    it 'raises an error if an absolute path is provided' do
      expect { repository.import_repository('./foo') }.to raise_error(ArgumentError, /disk path/)
    end

    it 'delegates to Gitaly' do
      expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |svc|
        expect(svc).to receive(:import_repository).with(url).and_return(nil)
      end

      repository.import_repository(url)
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :import_repository do
      subject { repository.import_repository('http://invalid.invalid') }
    end
  end

  describe '#replicate' do
    let(:new_repository) do
      Gitlab::Git::Repository.new('test_second_storage', TEST_REPO_PATH, '', 'group/project')
    end

    let(:new_repository_path) { File.join(TestEnv::SECOND_STORAGE_PATH, new_repository.relative_path) }

    subject { new_repository.replicate(repository) }

    before do
      stub_storage_settings('test_second_storage' => {
        'gitaly_address' => Gitlab.config.repositories.storages.default.gitaly_address,
        'path' => TestEnv::SECOND_STORAGE_PATH
      })
    end

    after do
      new_repository.remove
    end

    context 'destination does not exist' do
      it 'mirrors the source repository' do
        subject

        expect(refs(new_repository_path)).to eq(refs(repository_path))
      end
    end

    context 'destination exists' do
      before do
        new_repository.create_repository
      end

      it 'mirrors the source repository' do
        subject

        expect(refs(new_repository_path)).to eq(refs(repository_path))
      end

      context 'with keep-around refs' do
        let(:sha) { SeedRepo::Commit::ID }
        let(:keep_around_ref) { "refs/keep-around/#{sha}" }
        let(:tmp_ref) { "refs/tmp/#{SecureRandom.hex}" }

        before do
          repository.write_ref(keep_around_ref, sha)
          repository.write_ref(tmp_ref, sha)
        end

        it 'includes the temporary and keep-around refs' do
          subject

          expect(refs(new_repository_path)).to include(keep_around_ref)
          expect(refs(new_repository_path)).to include(tmp_ref)
        end
      end
    end
  end
end
