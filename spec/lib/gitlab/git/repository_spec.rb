# coding: utf-8
require "spec_helper"

describe Gitlab::Git::Repository, seed_helper: true do
  include Gitlab::EncodingHelper
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

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }
  let(:storage_path) { TestEnv.repos_path }
  let(:user) { build(:user) }

  describe '.create_hooks' do
    let(:repo_path) { File.join(storage_path, 'hook-test.git') }
    let(:hooks_dir) { File.join(repo_path, 'hooks') }
    let(:target_hooks_dir) { Gitlab.config.gitlab_shell.hooks_path }
    let(:existing_target) { File.join(repo_path, 'foobar') }

    before do
      FileUtils.rm_rf(repo_path)
      FileUtils.mkdir_p(repo_path)
    end

    context 'hooks is a directory' do
      let(:existing_file) { File.join(hooks_dir, 'my-file') }

      before do
        FileUtils.mkdir_p(hooks_dir)
        FileUtils.touch(existing_file)
        described_class.create_hooks(repo_path, target_hooks_dir)
      end

      it { expect(File.readlink(hooks_dir)).to eq(target_hooks_dir) }
      it { expect(Dir[File.join(repo_path, "hooks.old.*/my-file")].count).to eq(1) }
    end

    context 'hooks is a valid symlink' do
      before do
        FileUtils.mkdir_p existing_target
        File.symlink(existing_target, hooks_dir)
        described_class.create_hooks(repo_path, target_hooks_dir)
      end

      it { expect(File.readlink(hooks_dir)).to eq(target_hooks_dir) }
    end

    context 'hooks is a broken symlink' do
      before do
        FileUtils.rm_f(existing_target)
        File.symlink(existing_target, hooks_dir)
        described_class.create_hooks(repo_path, target_hooks_dir)
      end

      it { expect(File.readlink(hooks_dir)).to eq(target_hooks_dir) }
    end
  end

  describe "Respond to" do
    subject { repository }

    it { is_expected.to respond_to(:rugged) }
    it { is_expected.to respond_to(:root_ref) }
    it { is_expected.to respond_to(:tags) }
  end

  describe '#root_ref' do
    context 'with gitaly disabled' do
      before do
        allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)
      end

      it 'calls #discover_default_branch' do
        expect(repository).to receive(:discover_default_branch)
        repository.root_ref
      end
    end

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

  describe "#rugged" do
    describe 'when storage is broken', :broken_storage  do
      it 'raises a storage exception when storage is not available' do
        broken_repo = described_class.new('broken', 'a/path.git', '')

        expect { broken_repo.rugged }.to raise_error(Gitlab::Git::Storage::Inaccessible)
      end
    end

    it 'raises a no repository exception when there is no repo' do
      broken_repo = described_class.new('default', 'a/path.git', '')

      expect { broken_repo.rugged }.to raise_error(Gitlab::Git::Repository::NoRepository)
    end

    describe 'alternates keyword argument' do
      context 'with no Git env stored' do
        before do
          allow(Gitlab::Git::HookEnv).to receive(:all).and_return({})
        end

        it "is passed an empty array" do
          expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: [])

          repository.rugged
        end
      end

      context 'with absolute and relative Git object dir envvars stored' do
        before do
          allow(Gitlab::Git::HookEnv).to receive(:all).and_return({
            'GIT_OBJECT_DIRECTORY_RELATIVE' => './objects/foo',
            'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['./objects/bar', './objects/baz'],
            'GIT_OBJECT_DIRECTORY' => 'ignored',
            'GIT_ALTERNATE_OBJECT_DIRECTORIES' => %w[ignored ignored],
            'GIT_OTHER' => 'another_env'
          })
        end

        it "is passed the relative object dir envvars after being converted to absolute ones" do
          alternates = %w[foo bar baz].map { |d| File.join(repository.path, './objects', d) }
          expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: alternates)

          repository.rugged
        end
      end
    end
  end

  describe "#discover_default_branch" do
    let(:master) { 'master' }
    let(:feature) { 'feature' }
    let(:feature2) { 'feature2' }

    it "returns 'master' when master exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, master])
      expect(repository.discover_default_branch).to eq('master')
    end

    it "returns non-master when master exists but default branch is set to something else" do
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/feature')
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, master])
      expect(repository.discover_default_branch).to eq('feature')
      File.write(File.join(repository.path, 'HEAD'), 'ref: refs/heads/master')
    end

    it "returns a non-master branch when only one exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature])
      expect(repository.discover_default_branch).to eq('feature')
    end

    it "returns a non-master branch when more than one exists and master does not" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([feature, feature2])
      expect(repository.discover_default_branch).to eq('feature')
    end

    it "returns nil when no branch exists" do
      expect(repository).to receive(:branch_names).at_least(:once).and_return([])
      expect(repository.discover_default_branch).to be_nil
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

  shared_examples 'archive check' do |extenstion|
    it { expect(metadata['ArchivePath']).to match(%r{tmp/gitlab-git-test.git/gitlab-git-test-master-#{SeedRepo::LastCommit::ID}}) }
    it { expect(metadata['ArchivePath']).to end_with extenstion }
  end

  describe '#archive_prefix' do
    let(:project_name) { 'project-name'}

    before do
      expect(repository).to receive(:name).once.and_return(project_name)
    end

    it 'returns parameterised string for a ref containing slashes' do
      prefix = repository.archive_prefix('test/branch', 'SHA', append_sha: nil)

      expect(prefix).to eq("#{project_name}-test-branch-SHA")
    end

    it 'returns correct string for a ref containing dots' do
      prefix = repository.archive_prefix('test.branch', 'SHA', append_sha: nil)

      expect(prefix).to eq("#{project_name}-test.branch-SHA")
    end

    it 'returns string with sha when append_sha is false' do
      prefix = repository.archive_prefix('test.branch', 'SHA', append_sha: false)

      expect(prefix).to eq("#{project_name}-test.branch")
    end
  end

  describe '#archive' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', append_sha: true) }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#archive_zip' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'zip', append_sha: true) }

    it_should_behave_like 'archive check', '.zip'
  end

  describe '#archive_bz2' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'tbz2', append_sha: true) }

    it_should_behave_like 'archive check', '.tar.bz2'
  end

  describe '#archive_fallback' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'madeup', append_sha: true) }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#size' do
    subject { repository.size }

    it { is_expected.to be < 2 }
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
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }
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

  context '#submodules' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }

    context 'where repo has submodules' do
      let(:submodules) { repository.send(:submodules, 'master') }
      let(:submodule) { submodules.first }

      it { expect(submodules).to be_kind_of Hash }
      it { expect(submodules.empty?).to be_falsey }

      it 'should have valid data' do
        expect(submodule).to eq([
          "six", {
            "id" => "409f37c4f05865e4fb208c771485f211a22c4c2d",
            "name" => "six",
            "url" => "git://github.com/randx/six.git"
          }
        ])
      end

      it 'should handle nested submodules correctly' do
        nested = submodules['nested/six']
        expect(nested['name']).to eq('nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should handle deeply nested submodules correctly' do
        nested = submodules['deeper/nested/six']
        expect(nested['name']).to eq('deeper/nested/six')
        expect(nested['url']).to eq('git://github.com/randx/six.git')
        expect(nested['id']).to eq('24fb71c79fcabc63dfd8832b12ee3bf2bf06b196')
      end

      it 'should not have an entry for an invalid submodule' do
        expect(submodules).not_to have_key('invalid/path')
      end

      it 'should not have an entry for an uncommited submodule dir' do
        submodules = repository.send(:submodules, 'fix-existing-submodule-dir')
        expect(submodules).not_to have_key('submodule-existing-dir')
      end

      it 'should handle tags correctly' do
        submodules = repository.send(:submodules, 'v1.2.1')

        expect(submodules.first).to eq([
          "six", {
            "id" => "409f37c4f05865e4fb208c771485f211a22c4c2d",
            "name" => "six",
            "url" => "git://github.com/randx/six.git"
          }
        ])
      end

      it 'should not break on invalid syntax' do
        allow(repository).to receive(:blob_content).and_return(<<-GITMODULES.strip_heredoc)
          [submodule "six"]
          path = six
          url = git://github.com/randx/six.git

          [submodule]
          foo = bar
        GITMODULES

        expect(submodules).to have_key('six')
      end
    end

    context 'where repo doesn\'t have submodules' do
      let(:submodules) { repository.send(:submodules, '6d39438') }
      it 'should return an empty hash' do
        expect(submodules).to be_empty
      end
    end
  end

  describe '#commit_count' do
    shared_examples 'simple commit counting' do
      it { expect(repository.commit_count("master")).to eq(25) }
      it { expect(repository.commit_count("feature")).to eq(9) }
      it { expect(repository.commit_count("does-not-exist")).to eq(0) }
    end

    context 'when Gitaly commit_count feature is enabled' do
      it_behaves_like 'simple commit counting'
      it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::CommitService, :commit_count do
        subject { repository.commit_count('master') }
      end
    end

    context 'when Gitaly commit_count feature is disabled', :skip_gitaly_mock  do
      it_behaves_like 'simple commit counting'
    end
  end

  describe '#has_local_branches?' do
    shared_examples 'check for local branches' do
      it { expect(repository.has_local_branches?).to eq(true) }

      context 'mutable' do
        let(:repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

        after do
          ensure_seeds
        end

        it 'returns false when there are no branches' do
          # Sanity check
          expect(repository.has_local_branches?).to eq(true)

          FileUtils.rm_rf(File.join(repository.path, 'packed-refs'))
          heads_dir = File.join(repository.path, 'refs/heads')
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

    context 'with gitaly' do
      it_behaves_like 'check for local branches'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like 'check for local branches'
    end
  end

  describe "#delete_branch" do
    shared_examples "deleting a branch" do
      let(:repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

      after do
        ensure_seeds
      end

      it "removes the branch from the repo" do
        branch_name = "to-be-deleted-soon"

        repository.create_branch(branch_name)
        expect(repository.rugged.branches[branch_name]).not_to be_nil

        repository.delete_branch(branch_name)
        expect(repository.rugged.branches[branch_name]).to be_nil
      end

      context "when branch does not exist" do
        it "raises a DeleteBranchError exception" do
          expect { repository.delete_branch("this-branch-does-not-exist") }.to raise_error(Gitlab::Git::Repository::DeleteBranchError)
        end
      end
    end

    context "when Gitaly delete_branch is enabled" do
      it_behaves_like "deleting a branch"
    end

    context "when Gitaly delete_branch is disabled", :skip_gitaly_mock do
      it_behaves_like "deleting a branch"
    end
  end

  describe "#create_branch" do
    shared_examples 'creating a branch' do
      let(:repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

      after do
        ensure_seeds
      end

      it "should create a new branch" do
        expect(repository.create_branch('new_branch', 'master')).not_to be_nil
      end

      it "should create a new branch with the right name" do
        expect(repository.create_branch('another_branch', 'master').name).to eq('another_branch')
      end

      it "should fail if we create an existing branch" do
        repository.create_branch('duplicated_branch', 'master')
        expect {repository.create_branch('duplicated_branch', 'master')}.to raise_error("Branch duplicated_branch already exists")
      end

      it "should fail if we create a branch from a non existing ref" do
        expect {repository.create_branch('branch_based_in_wrong_ref', 'master_2_the_revenge')}.to raise_error("Invalid reference master_2_the_revenge")
      end
    end

    context 'when Gitaly create_branch feature is enabled' do
      it_behaves_like 'creating a branch'
    end

    context 'when Gitaly create_branch feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'creating a branch'
    end
  end

  describe '#delete_refs' do
    shared_examples 'deleting refs' do
      let(:repo) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

      after do
        ensure_seeds
      end

      it 'deletes the ref' do
        repo.delete_refs('refs/heads/feature')

        expect(repo.rugged.references['refs/heads/feature']).to be_nil
      end

      it 'deletes all refs' do
        refs = %w[refs/heads/wip refs/tags/v1.1.0]
        repo.delete_refs(*refs)

        refs.each do |ref|
          expect(repo.rugged.references[ref]).to be_nil
        end
      end

      it 'raises an error if it failed' do
        expect { repo.delete_refs('refs\heads\fix') }.to raise_error(Gitlab::Git::Repository::GitError)
      end
    end

    context 'when Gitaly delete_refs feature is enabled' do
      it_behaves_like 'deleting refs'
    end

    context 'when Gitaly delete_refs feature is disabled', :disable_gitaly do
      it_behaves_like 'deleting refs'
    end
  end

  describe '#branch_names_contains_sha' do
    shared_examples 'returning the right branches' do
      let(:head_id) { repository.rugged.head.target.oid }
      let(:new_branch) { head_id }
      let(:utf8_branch) { 'branch-é' }

      before do
        repository.create_branch(new_branch, 'master')
        repository.create_branch(utf8_branch, 'master')
      end

      after do
        repository.delete_branch(new_branch)
        repository.delete_branch(utf8_branch)
      end

      it 'displays that branch' do
        expect(repository.branch_names_contains_sha(head_id)).to include('master', new_branch, utf8_branch)
      end
    end

    context 'when Gitaly is enabled' do
      it_behaves_like 'returning the right branches'
    end

    context 'when Gitaly is disabled', :disable_gitaly do
      it_behaves_like 'returning the right branches'
    end
  end

  describe "#refs_hash" do
    subject { repository.refs_hash }

    it "should have as many entries as branches and tags" do
      expected_refs = SeedRepo::Repo::BRANCHES + SeedRepo::Repo::TAGS
      # We flatten in case a commit is pointed at by more than one branch and/or tag
      expect(subject.values.flatten.size).to eq(expected_refs.size)
    end

    it 'has valid commit ids as keys' do
      expect(subject.keys).to all( match(Commit::COMMIT_SHA_PATTERN) )
    end
  end

  describe "#remove_remote" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      @repo.remove_remote("expendable")
    end

    it "should remove the remote" do
      expect(@repo.rugged.remotes).not_to include("expendable")
    end

    after(:all) do
      ensure_seeds
    end
  end

  describe "#remote_update" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      @repo.remote_update("expendable", url: TEST_NORMAL_REPO_PATH)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes["expendable"].url).to(
        eq(TEST_NORMAL_REPO_PATH)
      )
    end

    after(:all) do
      ensure_seeds
    end
  end

  describe '#fetch_repository_as_mirror' do
    let(:new_repository) do
      Gitlab::Git::Repository.new('default', 'my_project.git', '')
    end

    subject { new_repository.fetch_repository_as_mirror(repository) }

    before do
      Gitlab::Shell.new.create_repository('default', 'my_project')
    end

    after do
      Gitlab::Shell.new.remove_repository(storage_path, 'my_project')
    end

    shared_examples 'repository mirror fecthing' do
      it 'fetches a repository as a mirror remote' do
        subject

        expect(refs(new_repository.path)).to eq(refs(repository.path))
      end

      context 'with keep-around refs' do
        let(:sha) { SeedRepo::Commit::ID }
        let(:keep_around_ref) { "refs/keep-around/#{sha}" }
        let(:tmp_ref) { "refs/tmp/#{SecureRandom.hex}" }

        before do
          repository.rugged.references.create(keep_around_ref, sha, force: true)
          repository.rugged.references.create(tmp_ref, sha, force: true)
        end

        it 'includes the temporary and keep-around refs' do
          subject

          expect(refs(new_repository.path)).to include(keep_around_ref)
          expect(refs(new_repository.path)).to include(tmp_ref)
        end
      end
    end

    context 'with gitaly enabled' do
      it_behaves_like 'repository mirror fecthing'
    end

    context 'with gitaly enabled', :skip_gitaly_mock do
      it_behaves_like 'repository mirror fecthing'
    end
  end

  describe '#remote_tags' do
    let(:remote_name) { 'upstream' }
    let(:target_commit_id) { SeedRepo::Commit::ID }
    let(:tag_name) { 'v0.0.1' }
    let(:tag_message) { 'My tag' }
    let(:remote_repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end

    subject { repository.remote_tags(remote_name) }

    before do
      repository.add_remote(remote_name, remote_repository.path)
      remote_repository.add_tag(tag_name, user: user, target: target_commit_id)
    end

    after do
      ensure_seeds
    end

    it 'gets the remote tags' do
      expect(subject.first).to be_an_instance_of(Gitlab::Git::Tag)
      expect(subject.first.name).to eq(tag_name)
      expect(subject.first.dereferenced_target.id).to eq(target_commit_id)
    end
  end

  describe "#log" do
    shared_examples 'repository log' do
      let(:commit_with_old_name) do
        Gitlab::Git::Commit.decorate(repository, @commit_with_old_name_id)
      end
      let(:commit_with_new_name) do
        Gitlab::Git::Commit.decorate(repository, @commit_with_new_name_id)
      end
      let(:rename_commit) do
        Gitlab::Git::Commit.decorate(repository, @rename_commit_id)
      end

      before(:context) do
        # Add new commits so that there's a renamed file in the commit history
        repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '').rugged
        @commit_with_old_name_id = new_commit_edit_old_file(repo)
        @rename_commit_id = new_commit_move_file(repo)
        @commit_with_new_name_id = new_commit_edit_new_file(repo)
      end

      after(:context) do
        # Erase our commits so other tests get the original repo
        repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '').rugged
        repo.references.update("refs/heads/master", SeedRepo::LastCommit::ID)
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

        it "should returns commits on or after that timestamp" do
          commits = repository.log(options)

          expect(commits.size).to be > 0
          expect(commits).to satisfy do |commits|
            commits.all? { |commit| commit.committed_date >= options[:after] }
          end
        end
      end

      context "where provides 'before' timestamp" do
        options = { before: Time.iso8601('2014-03-03T20:15:01+00:00') }

        it "should returns commits on or before that timestamp" do
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
          commit.rugged_diff_from_parent.deltas.flat_map do |delta|
            [delta.old_file[:path], delta.new_file[:path]].uniq.compact
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

    context 'when Gitaly find_commits feature is disabled', :disable_gitaly do
      it_behaves_like 'repository log'
    end
  end

  describe "#rugged_commits_between" do
    context 'two SHAs' do
      let(:first_sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:second_sha) { '0e50ec4d3c7ce42ab74dda1d422cb2cbffe1e326' }

      it 'returns the number of commits between' do
        expect(repository.rugged_commits_between(first_sha, second_sha).count).to eq(3)
      end
    end

    context 'SHA and master branch' do
      let(:sha) { 'b0e52af38d7ea43cf41d8a6f2471351ac036d6c9' }
      let(:branch) { 'master' }

      it 'returns the number of commits between a sha and a branch' do
        expect(repository.rugged_commits_between(sha, branch).count).to eq(5)
      end

      it 'returns the number of commits between a branch and a sha' do
        expect(repository.rugged_commits_between(branch, sha).count).to eq(0) # sha is before branch
      end
    end

    context 'two branches' do
      let(:first_branch) { 'feature' }
      let(:second_branch) { 'master' }

      it 'returns the number of commits between' do
        expect(repository.rugged_commits_between(first_branch, second_branch).count).to eq(17)
      end
    end
  end

  describe '#count_commits_between' do
    subject { repository.count_commits_between('feature', 'master') }

    it { is_expected.to eq(17) }
  end

  describe '#merge_base' do
    shared_examples '#merge_base' do
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

    context 'with gitaly' do
      it_behaves_like '#merge_base'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#merge_base'
    end
  end

  describe '#count_commits' do
    shared_examples 'extended commit counting' do
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
        it 'returns the number of commits with path ' do
          options = { ref: 'master', max_count: 5 }

          expect(repository.count_commits(options)).to eq(5)
        end
      end

      context 'with path' do
        it 'returns the number of commits with path ' do
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
            it 'returns the number of commits with path ' do
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

    context 'when Gitaly count_commits feature is enabled' do
      it_behaves_like 'extended commit counting'
    end

    context 'when Gitaly count_commits feature is disabled', :disable_gitaly do
      it_behaves_like 'extended commit counting'
    end
  end

  describe '#autocrlf' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      @repo.rugged.config['core.autocrlf'] = true
    end

    it 'return the value of the autocrlf option' do
      expect(@repo.autocrlf).to be(true)
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#autocrlf=' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      @repo.rugged.config['core.autocrlf'] = false
    end

    it 'should set the autocrlf option to the provided option' do
      @repo.autocrlf = :input

      File.open(File.join(SEED_STORAGE_PATH, TEST_MUTABLE_REPO_PATH, 'config')) do |config_file|
        expect(config_file.read).to match('autocrlf = input')
      end
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#find_branch' do
    shared_examples 'finding a branch' do
      it 'should return a Branch for master' do
        branch = repository.find_branch('master')

        expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
        expect(branch.name).to eq('master')
      end

      it 'should handle non-existent branch' do
        branch = repository.find_branch('this-is-garbage')

        expect(branch).to eq(nil)
      end
    end

    context 'when Gitaly find_branch feature is enabled' do
      it_behaves_like 'finding a branch'
    end

    context 'when Gitaly find_branch feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'finding a branch'

      context 'force_reload is true' do
        it 'should reload Rugged::Repository' do
          expect(Rugged::Repository).to receive(:new).twice.and_call_original

          repository.find_branch('master')
          branch = repository.find_branch('master', force_reload: true)

          expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
          expect(branch.name).to eq('master')
        end
      end

      context 'force_reload is false' do
        it 'should not reload Rugged::Repository' do
          expect(Rugged::Repository).to receive(:new).once.and_call_original

          branch = repository.find_branch('master', force_reload: false)

          expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
          expect(branch.name).to eq('master')
        end
      end
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
      let(:repository) do
        Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      end

      before do
        create_remote_branch(repository, 'joe', 'remote_branch', 'master')
        repository.create_branch('local_branch', 'master')
      end

      after do
        ensure_seeds
      end

      it 'returns the local and remote branches' do
        expect(subject.any? { |b| b.name == 'joe/remote_branch' }).to eq(true)
        expect(subject.any? { |b| b.name == 'local_branch' }).to eq(true)
      end
    end

    # With Gitaly enabled, Gitaly just doesn't return deleted branches.
    context 'with deleted branch with Gitaly disabled' do
      before do
        allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(false)
      end

      it 'returns no results' do
        ref = double()
        allow(ref).to receive(:name) { 'bad-branch' }
        allow(ref).to receive(:target) { raise Rugged::ReferenceError }
        branches = double()
        allow(branches).to receive(:each) { [ref].each }
        allow(repository.rugged).to receive(:branches) { branches }

        expect(subject).to be_empty
      end
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :branches
  end

  describe '#branch_count' do
    it 'returns the number of branches' do
      expect(repository.branch_count).to eq(10)
    end

    context 'with local and remote branches' do
      let(:repository) do
        Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
      end

      before do
        create_remote_branch(repository, 'joe', 'remote_branch', 'master')
        repository.create_branch('local_branch', 'master')
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
    shared_examples 'finding merged branch names' do
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
          repository.create_branch('identical', 'master')
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

    context 'when Gitaly merged_branch_names feature is enabled' do
      it_behaves_like 'finding merged branch names'
    end

    context 'when Gitaly merged_branch_names feature is disabled', :disable_gitaly do
      it_behaves_like 'finding merged branch names'
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
    shared_examples 'applying git attributes' do
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
          repository.create_branch(branch_name, "master")
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

    context 'when gitaly is enabled' do
      it_behaves_like 'applying git attributes'
    end

    context 'when gitaly is disabled', :disable_gitaly do
      it_behaves_like 'applying git attributes'
    end
  end

  describe '#ref_exists?' do
    shared_examples 'checks the existence of refs' do
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

    context 'when Gitaly ref_exists feature is enabled' do
      it_behaves_like 'checks the existence of refs'
    end

    context 'when Gitaly ref_exists feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'checks the existence of refs'
    end
  end

  describe '#tag_exists?' do
    shared_examples 'checks the existence of tags' do
      it 'returns true for an existing tag' do
        tag = repository.tag_names.first

        expect(repository.tag_exists?(tag)).to eq(true)
      end

      it 'returns false for a non-existing tag' do
        expect(repository.tag_exists?('v9000')).to eq(false)
      end
    end

    context 'when Gitaly ref_exists_tags feature is enabled' do
      it_behaves_like 'checks the existence of tags'
    end

    context 'when Gitaly ref_exists_tags feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'checks the existence of tags'
    end
  end

  describe '#branch_exists?' do
    shared_examples 'checks the existence of branches' do
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

    context 'when Gitaly ref_exists_branches feature is enabled' do
      it_behaves_like 'checks the existence of branches'
    end

    context 'when Gitaly ref_exists_branches feature is disabled', :skip_gitaly_mock do
      it_behaves_like 'checks the existence of branches'
    end
  end

  describe '#batch_existence' do
    let(:refs) { ['deadbeef', SeedRepo::RubyBlob::ID, '909e6157199'] }

    it 'returns existing refs back' do
      result = repository.batch_existence(refs)

      expect(result).to eq([SeedRepo::RubyBlob::ID])
    end

    context 'existing: true' do
      it 'inverts meaning and returns non-existing refs' do
        result = repository.batch_existence(refs, existing: false)

        expect(result).to eq(%w(deadbeef 909e6157199))
      end
    end
  end

  describe '#local_branches' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end

    after(:all) do
      ensure_seeds
    end

    it 'returns the local branches' do
      create_remote_branch(@repo, 'joe', 'remote_branch', 'master')
      @repo.create_branch('local_branch', 'master')

      expect(@repo.local_branches.any? { |branch| branch.name == 'remote_branch' }).to eq(false)
      expect(@repo.local_branches.any? { |branch| branch.name == 'local_branch' }).to eq(true)
    end

    it 'returns a Branch with UTF-8 fields' do
      branches = @repo.local_branches.to_a
      expect(branches.size).to be > 0
      branches.each do |branch|
        expect(branch.name).to be_utf8
        expect(branch.target).to be_utf8 unless branch.target.nil?
      end
    end

    it 'gets the branches from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:local_branches)
        .and_return([])
      @repo.local_branches
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :local_branches do
      subject { @repo.local_branches }
    end
  end

  describe '#languages' do
    shared_examples 'languages' do
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

    it_behaves_like 'languages'

    context 'with rugged', :skip_gitaly_mock do
      it_behaves_like 'languages'
    end
  end

  describe '#license_short_name' do
    shared_examples 'acquiring the Licensee license key' do
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

    context 'when gitaly is enabled' do
      it_behaves_like 'acquiring the Licensee license key'
    end

    context 'when gitaly is disabled', :disable_gitaly do
      it_behaves_like 'acquiring the Licensee license key'
    end
  end

  describe '#with_repo_branch_commit' do
    context 'when comparing with the same repository' do
      let(:start_repository) { repository }

      context 'when the branch exists' do
        let(:start_branch_name) { 'master' }

        it 'yields the commit' do
          expect { |b| repository.with_repo_branch_commit(start_repository, start_branch_name, &b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Commit))
        end
      end

      context 'when the branch does not exist' do
        let(:start_branch_name) { 'definitely-not-master' }

        it 'yields nil' do
          expect { |b| repository.with_repo_branch_commit(start_repository, start_branch_name, &b) }
            .to yield_with_args(nil)
        end
      end
    end

    context 'when comparing with another repository' do
      let(:start_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

      context 'when the branch exists' do
        let(:start_branch_name) { 'master' }

        it 'yields the commit' do
          expect { |b| repository.with_repo_branch_commit(start_repository, start_branch_name, &b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Commit))
        end
      end

      context 'when the branch does not exist' do
        let(:start_branch_name) { 'definitely-not-master' }

        it 'yields nil' do
          expect { |b| repository.with_repo_branch_commit(start_repository, start_branch_name, &b) }
            .to yield_with_args(nil)
        end
      end
    end
  end

  describe '#fetch_source_branch!' do
    shared_examples '#fetch_source_branch!' do
      let(:local_ref) { 'refs/merge-requests/1/head' }
      let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }
      let(:source_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

      after do
        ensure_seeds
      end

      context 'when the branch exists' do
        context 'when the commit does not exist locally' do
          let(:source_branch) { 'new-branch-for-fetch-source-branch' }
          let(:source_rugged) { source_repository.rugged }
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

    it_behaves_like '#fetch_source_branch!'

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#fetch_source_branch!'
    end
  end

  describe '#rm_branch' do
    shared_examples "user deleting a branch" do
      let(:project) { create(:project, :repository) }
      let(:repository) { project.repository.raw }
      let(:branch_name) { "to-be-deleted-soon" }

      before do
        project.add_developer(user)
        repository.create_branch(branch_name)
      end

      it "removes the branch from the repo" do
        repository.rm_branch(branch_name, user: user)

        expect(repository.rugged.branches[branch_name]).to be_nil
      end
    end

    context "when Gitaly user_delete_branch is enabled" do
      it_behaves_like "user deleting a branch"
    end

    context "when Gitaly user_delete_branch is disabled", :skip_gitaly_mock do
      it_behaves_like "user deleting a branch"
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
  end

  describe '#write_config' do
    before do
      repository.rugged.config["gitlab.fullpath"] = repository.path
    end

    shared_examples 'writing repo config' do
      context 'is given a path' do
        it 'writes it to disk' do
          repository.write_config(full_path: "not-the/real-path.git")

          config = File.read(File.join(repository.path, "config"))

          expect(config).to include("[gitlab]")
          expect(config).to include("fullpath = not-the/real-path.git")
        end
      end

      context 'it is given an empty path' do
        it 'does not write it to disk' do
          repository.write_config(full_path: "")

          config = File.read(File.join(repository.path, "config"))

          expect(config).to include("[gitlab]")
          expect(config).to include("fullpath = #{repository.path}")
        end
      end
    end

    context "when gitaly_write_config is enabled" do
      it_behaves_like "writing repo config"
    end

    context "when gitaly_write_config is disabled", :disable_gitaly do
      it_behaves_like "writing repo config"
    end
  end

  describe '#merge' do
    let(:repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end
    let(:source_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
    let(:target_branch) { 'test-merge-target-branch' }

    before do
      repository.create_branch(target_branch, '6d394385cf567f80a8fd85055db1ab4c5295806f')
    end

    after do
      ensure_seeds
    end

    shared_examples '#merge' do
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

    context 'with gitaly' do
      it_behaves_like '#merge'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#merge'
    end
  end

  describe '#ff_merge' do
    let(:repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end
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

    context 'with gitaly' do
      it "calls Gitaly's OperationService" do
        expect_any_instance_of(Gitlab::GitalyClient::OperationService)
          .to receive(:user_ff_branch).with(user, source_sha, target_branch)
          .and_return(nil)

        subject
      end

      it_behaves_like '#ff_merge'
    end

    context 'without gitaly', :skip_gitaly_mock do
      it_behaves_like '#ff_merge'
    end
  end

  describe '#delete_all_refs_except' do
    let(:repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end

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

  describe 'remotes' do
    let(:repository) do
      Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '')
    end
    let(:remote_name) { 'my-remote' }

    after do
      ensure_seeds
    end

    describe '#add_remote' do
      let(:url) { 'http://my-repo.git' }
      let(:mirror_refmap) { '+refs/*:refs/*' }

      it 'creates a new remote via Gitaly' do
        expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
          .to receive(:add_remote).with(remote_name, url, mirror_refmap)

        repository.add_remote(remote_name, url, mirror_refmap: mirror_refmap)
      end

      context 'with Gitaly disabled', :skip_gitaly_mock do
        it 'creates a new remote via Rugged' do
          expect_any_instance_of(Rugged::RemoteCollection).to receive(:create)
            .with(remote_name, url)
          expect_any_instance_of(Rugged::Config).to receive(:[]=)
          .with("remote.#{remote_name}.mirror", true)
          expect_any_instance_of(Rugged::Config).to receive(:[]=)
          .with("remote.#{remote_name}.prune", true)
          expect_any_instance_of(Rugged::Config).to receive(:[]=)
            .with("remote.#{remote_name}.fetch", mirror_refmap)

          repository.add_remote(remote_name, url, mirror_refmap: mirror_refmap)
        end
      end
    end

    describe '#remove_remote' do
      it 'removes the remote via Gitaly' do
        expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
          .to receive(:remove_remote).with(remote_name)

        repository.remove_remote(remote_name)
      end

      context 'with Gitaly disabled', :skip_gitaly_mock do
        it 'removes the remote via Rugged' do
          expect_any_instance_of(Rugged::RemoteCollection).to receive(:delete)
            .with(remote_name)

          repository.remove_remote(remote_name)
        end
      end
    end
  end

  describe '#gitlab_projects' do
    subject { repository.gitlab_projects }

    it { expect(subject.shard_path).to eq(storage_path) }
    it { expect(subject.repository_relative_path).to eq(repository.relative_path) }
  end

  describe '#bundle_to_disk' do
    shared_examples 'bundling to disk' do
      let(:save_path) { File.join(Dir.tmpdir, "repo-#{SecureRandom.hex}.bundle") }

      after do
        FileUtils.rm_rf(save_path)
      end

      it 'saves a bundle to disk' do
        repository.bundle_to_disk(save_path)

        success = system(
          *%W(#{Gitlab.config.git.bin_path} -C #{repository.path} bundle verify #{save_path}),
          [:out, :err] => '/dev/null'
        )
        expect(success).to be true
      end
    end

    context 'when Gitaly bundle_to_disk feature is enabled' do
      it_behaves_like 'bundling to disk'
    end

    context 'when Gitaly bundle_to_disk feature is disabled', :disable_gitaly do
      it_behaves_like 'bundling to disk'
    end
  end

  describe '#create_from_bundle' do
    shared_examples 'creating repo from bundle' do
      let(:bundle_path) { File.join(Dir.tmpdir, "repo-#{SecureRandom.hex}.bundle") }
      let(:project) { create(:project) }
      let(:imported_repo) { project.repository.raw }

      before do
        expect(repository.bundle_to_disk(bundle_path)).to be true
      end

      after do
        FileUtils.rm_rf(bundle_path)
      end

      it 'creates a repo from a bundle file' do
        expect(imported_repo).not_to exist

        result = imported_repo.create_from_bundle(bundle_path)

        expect(result).to be true
        expect(imported_repo).to exist
        expect { imported_repo.fsck }.not_to raise_exception
      end

      it 'creates a symlink to the global hooks dir' do
        imported_repo.create_from_bundle(bundle_path)
        hooks_path = File.join(imported_repo.path, 'hooks')

        expect(File.readlink(hooks_path)).to eq(Gitlab.config.gitlab_shell.hooks_path)
      end
    end

    context 'when Gitaly create_repo_from_bundle feature is enabled' do
      it_behaves_like 'creating repo from bundle'
    end

    context 'when Gitaly create_repo_from_bundle feature is disabled', :disable_gitaly do
      it_behaves_like 'creating repo from bundle'
    end
  end

  describe '#checksum' do
    shared_examples 'calculating checksum' do
      it 'calculates the checksum for non-empty repo' do
        expect(repository.checksum).to eq '54f21be4c32c02f6788d72207fa03ad3bce725e4'
      end

      it 'returns 0000000000000000000000000000000000000000 for an empty repo' do
        FileUtils.rm_rf(File.join(storage_path, 'empty-repo.git'))

        system(git_env, *%W(#{Gitlab.config.git.bin_path} init --bare empty-repo.git),
               chdir: storage_path,
               out:   '/dev/null',
               err:   '/dev/null')

        empty_repo = described_class.new('default', 'empty-repo.git', '')

        expect(empty_repo.checksum).to eq '0000000000000000000000000000000000000000'
      end

      it 'raises a no repository exception when there is no repo' do
        broken_repo = described_class.new('default', 'a/path.git', '')

        expect { broken_repo.checksum }.to raise_error(Gitlab::Git::Repository::NoRepository)
      end
    end

    context 'when calculate_checksum Gitaly feature is enabled' do
      it_behaves_like 'calculating checksum'
    end

    context 'when calculate_checksum Gitaly feature is disabled', :disable_gitaly do
      it_behaves_like 'calculating checksum'

      describe 'when storage is broken', :broken_storage  do
        it 'raises a storage exception when storage is not available' do
          broken_repo = described_class.new('broken', 'a/path.git', '')

          expect { broken_repo.rugged }.to raise_error(Gitlab::Git::Storage::Inaccessible)
        end
      end

      it "raises a Gitlab::Git::Repository::Failure error if the `popen` call to git returns a non-zero exit code" do
        allow(repository).to receive(:popen).and_return(['output', nil])

        expect { repository.checksum }.to raise_error Gitlab::Git::Repository::ChecksumError
      end
    end
  end

  context 'gitlab_projects commands' do
    let(:gitlab_projects) { repository.gitlab_projects }
    let(:timeout) { Gitlab.config.gitlab_shell.git_timeout }

    describe '#push_remote_branches' do
      subject do
        repository.push_remote_branches('downstream-remote', ['master'])
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:push_branches)
          .with('downstream-remote', timeout, true, ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'raises an error if the command fails' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:push_branches)
          .with('downstream-remote', timeout, true, ['master'])
          .and_return(false)

        expect { subject }.to raise_error(Gitlab::Git::CommandError, 'error')
      end
    end

    describe '#delete_remote_branches' do
      subject do
        repository.delete_remote_branches('downstream-remote', ['master'])
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'raises an error if the command fails' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(false)

        expect { subject }.to raise_error(Gitlab::Git::CommandError, 'error')
      end
    end

    describe '#delete_remote_branches' do
      subject do
        repository.delete_remote_branches('downstream-remote', ['master'])
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'raises an error if the command fails' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(false)

        expect { subject }.to raise_error(Gitlab::Git::CommandError, 'error')
      end
    end

    describe '#clean_stale_repository_files' do
      let(:worktree_path) { File.join(repository.path, 'worktrees', 'delete-me') }

      it 'cleans up the files' do
        repository.with_worktree(worktree_path, 'master', env: ENV) do
          FileUtils.touch(worktree_path, mtime: Time.now - 8.hours)
          # git rev-list --all will fail in git 2.16 if HEAD is pointing to a non-existent object,
          # but the HEAD must be 40 characters long or git will ignore it.
          File.write(File.join(worktree_path, 'HEAD'), Gitlab::Git::BLANK_SHA)

          # git 2.16 fails with "fatal: bad object HEAD"
          expect { repository.rev_list(including: :all) }.to raise_error(Gitlab::Git::Repository::GitError)

          repository.clean_stale_repository_files

          expect { repository.rev_list(including: :all) }.not_to raise_error
          expect(File.exist?(worktree_path)).to be_falsey
        end
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

    describe '#delete_remote_branches' do
      subject do
        repository.delete_remote_branches('downstream-remote', ['master'])
      end

      it 'executes the command' do
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(true)

        is_expected.to be_truthy
      end

      it 'raises an error if the command fails' do
        allow(gitlab_projects).to receive(:output) { 'error' }
        expect(gitlab_projects).to receive(:delete_remote_branches)
          .with('downstream-remote', ['master'])
          .and_return(false)

        expect { subject }.to raise_error(Gitlab::Git::CommandError, 'error')
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

      context 'sparse checkout', :skip_gitaly_mock do
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
          let(:repo) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '').rugged }
          let(:end_sha) { new_commit_move_file(repo).oid }

          after do
            # Erase our commits so other tests get the original repo
            repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '').rugged
            repo.references.update('refs/heads/master', SeedRepo::LastCommit::ID)
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

      context 'with an ASCII-8BIT diff', :skip_gitaly_mock do
        let(:diff) { "diff --git a/README.md b/README.md\nindex faaf198..43c5edf 100644\n--- a/README.md\n+++ b/README.md\n@@ -1,4 +1,4 @@\n-testme\n+✓ testme\n ======\n \n Sample repo for testing gitlab features\n" }

        it 'applies a ASCII-8BIT diff' do
          allow(repository).to receive(:run_git!).and_call_original
          allow(repository).to receive(:run_git!).with(%W(diff --binary #{start_sha}...#{end_sha})).and_return(diff.force_encoding('ASCII-8BIT'))

          expect(subject).to match(/\h{40}/)
        end
      end

      context 'with trailing whitespace in an invalid patch', :skip_gitaly_mock do
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
  end

  def create_remote_branch(repository, remote_name, branch_name, source_branch_name)
    source_branch = repository.branches.find { |branch| branch.name == source_branch_name }
    rugged = repository.rugged
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", source_branch.dereferenced_target.sha)
  end

  # Build the options hash that's passed to Rugged::Commit#create
  def commit_options(repo, index, message)
    options = {}
    options[:tree] = index.write_tree(repo)
    options[:author] = {
      email: "test@example.com",
      name: "Test Author",
      time: Time.gm(2014, "mar", 3, 20, 15, 1)
    }
    options[:committer] = {
      email: "test@example.com",
      name: "Test Author",
      time: Time.gm(2014, "mar", 3, 20, 15, 1)
    }
    options[:message] ||= message
    options[:parents] = repo.empty? ? [] : [repo.head.target].compact
    options[:update_ref] = "HEAD"

    options
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
  # contents of CHANGELOG with a single new line of text.
  def new_commit_edit_old_file(repo)
    oid = repo.write("I replaced the changelog with this text", :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "CHANGELOG", oid: oid, mode: 0100644)

    options = commit_options(
      repo,
      index,
      "Edit CHANGELOG in its original location"
    )

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Replaces the
  # contents of encoding/CHANGELOG with new text.
  def new_commit_edit_new_file(repo)
    oid = repo.write("I'm a new changelog with different text", :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)

    options = commit_options(repo, index, "Edit encoding/CHANGELOG")

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  # Writes a new commit to the repo and returns a Rugged::Commit.  Moves the
  # CHANGELOG file to the encoding/ directory.
  def new_commit_move_file(repo)
    blob_oid = repo.head.target.tree.detect { |i| i[:name] == "CHANGELOG" }[:oid]
    file_content = repo.lookup(blob_oid).content
    oid = repo.write(file_content, :blob)
    index = repo.index
    index.read_tree(repo.head.target.tree)
    index.add(path: "encoding/CHANGELOG", oid: oid, mode: 0100644)
    index.remove("CHANGELOG")

    options = commit_options(repo, index, "Move CHANGELOG to encoding/")

    sha = Rugged::Commit.create(repo, options)
    repo.lookup(sha)
  end

  def refs(dir)
    IO.popen(%W[git -C #{dir} for-each-ref], &:read).split("\n").map do |line|
      line.split("\t").last
    end
  end
end
