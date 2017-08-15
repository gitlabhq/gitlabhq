require "spec_helper"

describe Gitlab::Git::Repository, seed_helper: true do
  include Gitlab::EncodingHelper

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

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }

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
    describe 'when storage is broken', broken_storage: true  do
      it 'raises a storage exception when storage is not available' do
        broken_repo = described_class.new('broken', 'a/path.git')

        expect { broken_repo.rugged }.to raise_error(Gitlab::Git::Storage::Inaccessible)
      end
    end

    it 'raises a no repository exception when there is no repo' do
      broken_repo = described_class.new('default', 'a/path.git')

      expect { broken_repo.rugged }.to raise_error(Gitlab::Git::Repository::NoRepository)
    end

    context 'with no Git env stored' do
      before do
        expect(Gitlab::Git::Env).to receive(:all).and_return({})
      end

      it "whitelist some variables and pass them via the alternates keyword argument" do
        expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: [])

        repository.rugged
      end
    end

    context 'with some Git env stored' do
      before do
        expect(Gitlab::Git::Env).to receive(:all).and_return({
          'GIT_OBJECT_DIRECTORY' => 'foo',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES' => 'bar',
          'GIT_OTHER' => 'another_env'
        })
      end

      it "whitelist some variables and pass them via the alternates keyword argument" do
        expect(Rugged::Repository).to receive(:new).with(repository.path, alternates: %w[foo bar])

        repository.rugged
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
    it { expect(metadata['ArchivePath']).to match(/tmp\/gitlab-git-test.git\/gitlab-git-test-master-#{SeedRepo::LastCommit::ID}/) }
    it { expect(metadata['ArchivePath']).to end_with extenstion }
  end

  describe '#archive_prefix' do
    let(:project_name) { 'project-name'}

    before do
      expect(repository).to receive(:name).once.and_return(project_name)
    end

    it 'returns parameterised string for a ref containing slashes' do
      prefix = repository.archive_prefix('test/branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test-branch-SHA")
    end

    it 'returns correct string for a ref containing dots' do
      prefix = repository.archive_prefix('test.branch', 'SHA')

      expect(prefix).to eq("#{project_name}-test.branch-SHA")
    end
  end

  describe '#archive' do
    let(:metadata) { repository.archive_metadata('master', '/tmp') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#archive_zip' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'zip') }

    it_should_behave_like 'archive check', '.zip'
  end

  describe '#archive_bz2' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'tbz2') }

    it_should_behave_like 'archive check', '.tar.bz2'
  end

  describe '#archive_fallback' do
    let(:metadata) { repository.archive_metadata('master', '/tmp', 'madeup') }

    it_should_behave_like 'archive check', '.tar.gz'
  end

  describe '#size' do
    subject { repository.size }

    it { is_expected.to be < 2 }
  end

  describe '#has_commits?' do
    it { expect(repository.has_commits?).to be_truthy }
  end

  describe '#empty?' do
    it { expect(repository.empty?).to be_falsey }
  end

  describe '#bare?' do
    it { expect(repository.bare?).to be_truthy }
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
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }
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
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH) }

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
    end

    context 'when Gitaly commit_count feature is enabled' do
      it_behaves_like 'simple commit counting'
      it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::CommitService, :commit_count do
        subject { repository.commit_count('master') }
      end
    end

    context 'when Gitaly commit_count feature is disabled', skip_gitaly_mock: true  do
      it_behaves_like 'simple commit counting'
    end
  end

  describe "#delete_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.delete_branch("feature")
    end

    it "should remove the branch from the repo" do
      expect(@repo.rugged.branches["feature"]).to be_nil
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#create_branch" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
    end

    it "should create a new branch" do
      expect(@repo.create_branch('new_branch', 'master')).not_to be_nil
    end

    it "should create a new branch with the right name" do
      expect(@repo.create_branch('another_branch', 'master').name).to eq('another_branch')
    end

    it "should fail if we create an existing branch" do
      @repo.create_branch('duplicated_branch', 'master')
      expect{@repo.create_branch('duplicated_branch', 'master')}.to raise_error("Branch duplicated_branch already exists")
    end

    it "should fail if we create a branch from a non existing ref" do
      expect{@repo.create_branch('branch_based_in_wrong_ref', 'master_2_the_revenge')}.to raise_error("Invalid reference master_2_the_revenge")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_names" do
    let(:remotes) { repository.remote_names }

    it "should have one entry: 'origin'" do
      expect(remotes.size).to eq(1)
      expect(remotes.first).to eq("origin")
    end
  end

  describe "#refs_hash" do
    let(:refs) { repository.refs_hash }

    it "should have as many entries as branches and tags" do
      expected_refs = SeedRepo::Repo::BRANCHES + SeedRepo::Repo::TAGS
      # We flatten in case a commit is pointed at by more than one branch and/or tag
      expect(refs.values.flatten.size).to eq(expected_refs.size)
    end
  end

  describe "#remote_delete" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_delete("expendable")
    end

    it "should remove the remote" do
      expect(@repo.rugged.remotes).not_to include("expendable")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_add" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_add("new_remote", SeedHelper::GITLAB_GIT_TEST_REPO_URL)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes.each_name.to_a).to include("new_remote")
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#remote_update" do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.remote_update("expendable", url: TEST_NORMAL_REPO_PATH)
    end

    it "should add the remote" do
      expect(@repo.rugged.remotes["expendable"].url).to(
        eq(TEST_NORMAL_REPO_PATH)
      )
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
      ensure_seeds
    end
  end

  describe "#log" do
    commit_with_old_name = nil
    commit_with_new_name = nil
    rename_commit = nil

    before(:context) do
      # Add new commits so that there's a renamed file in the commit history
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged

      commit_with_old_name = Gitlab::Git::Commit.decorate(new_commit_edit_old_file(repo))
      rename_commit = Gitlab::Git::Commit.decorate(new_commit_move_file(repo))
      commit_with_new_name = Gitlab::Git::Commit.decorate(new_commit_edit_new_file(repo))
    end

    after(:context) do
      # Erase our commits so other tests get the original repo
      repo = Gitlab::Git::Repository.new('default', TEST_REPO_PATH).rugged
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

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the new filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "encoding/CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_new_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_old_name)
        end
      end

      context "and 'path' is a file that matches the old filename" do
        let(:log_commits) do
          repository.log(options.merge(path: "CHANGELOG"))
        end

        it "should not follow renames" do
          expect(log_commits).to include(commit_with_old_name)
          expect(log_commits).to include(rename_commit)
          expect(log_commits).not_to include(commit_with_new_name)
        end
      end

      context "and 'path' includes a directory that used to be a file" do
        let(:log_commits) do
          repository.log(options.merge(ref: "refs/heads/fix-blob-path", path: "files/testdir/file.txt"))
        end

        it "should return a list of commits" do
          expect(log_commits.size).to eq(1)
        end
      end
    end

    context "compare results between log_by_walk and log_by_shell" do
      let(:options) { { ref: "master" } }
      let(:commits_by_walk) { repository.log(options).map(&:id) }
      let(:commits_by_shell) { repository.log(options.merge({ disable_walk: true })).map(&:id) }

      it { expect(commits_by_walk).to eq(commits_by_shell) }

      context "with limit" do
        let(:options) { { ref: "master", limit: 1 } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with offset" do
        let(:options) { { ref: "master", offset: 1 } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with skip_merges" do
        let(:options) { { ref: "master", skip_merges: true } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }
      end

      context "with path" do
        let(:options) { { ref: "master", path: "encoding" } }

        it { expect(commits_by_walk).to eq(commits_by_shell) }

        context "with follow" do
          let(:options) { { ref: "master", path: "encoding", follow: true } }

          it { expect(commits_by_walk).to eq(commits_by_shell) }
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
        commit.diff_from_parent.deltas.flat_map do |delta|
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

  describe '#count_commits' do
    shared_examples 'extended commit counting' do
      context 'with after timestamp' do
        it 'returns the number of commits after timestamp' do
          options = { ref: 'master', limit: nil, after: Time.iso8601('2013-03-03T20:15:01+00:00') }

          expect(repository.count_commits(options)).to eq(25)
        end
      end

      context 'with before timestamp' do
        it 'returns the number of commits before timestamp' do
          options = { ref: 'feature', limit: nil, before: Time.iso8601('2015-03-03T20:15:01+00:00') }

          expect(repository.count_commits(options)).to eq(9)
        end
      end

      context 'with path' do
        it 'returns the number of commits with path ' do
          options = { ref: 'master', limit: nil, path: "encoding" }

          expect(repository.count_commits(options)).to eq(2)
        end
      end
    end

    context 'when Gitaly count_commits feature is enabled' do
      it_behaves_like 'extended commit counting'
    end

    context 'when Gitaly count_commits feature is disabled', skip_gitaly_mock: true do
      it_behaves_like 'extended commit counting'
    end
  end

  describe "branch_names_contains" do
    subject { repository.branch_names_contains(SeedRepo::LastCommit::ID) }

    it { is_expected.to include('master') }
    it { is_expected.not_to include('feature') }
    it { is_expected.not_to include('fix') }
  end

  describe '#autocrlf' do
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
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
      @repo = Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH)
      @repo.rugged.config['core.autocrlf'] = false
    end

    it 'should set the autocrlf option to the provided option' do
      @repo.autocrlf = :input

      File.open(File.join(SEED_STORAGE_PATH, TEST_MUTABLE_REPO_PATH, '.git', 'config')) do |config_file|
        expect(config_file.read).to match('autocrlf = input')
      end
    end

    after(:all) do
      @repo.rugged.config.delete('core.autocrlf')
    end
  end

  describe '#find_branch' do
    it 'should return a Branch for master' do
      branch = repository.find_branch('master')

      expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
      expect(branch.name).to eq('master')
    end

    it 'should handle non-existent branch' do
      branch = repository.find_branch('this-is-garbage')

      expect(branch).to eq(nil)
    end

    it 'should reload Rugged::Repository and return master' do
      expect(Rugged::Repository).to receive(:new).twice.and_call_original

      repository.find_branch('master')
      branch = repository.find_branch('master', force_reload: true)

      expect(branch).to be_a_kind_of(Gitlab::Git::Branch)
      expect(branch.name).to eq('master')
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
        Gitlab::Git::Repository.new('default', File.join(TEST_MUTABLE_REPO_PATH, '.git'))
      end

      before do
        create_remote_branch(repository, 'joe', 'remote_branch', 'master')
        repository.create_branch('local_branch', 'master')
      end

      after do
        FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
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
  end

  describe "#ls_files" do
    let(:master_file_paths) { repository.ls_files("master") }
    let(:not_existed_branch) { repository.ls_files("not_existed_branch") }

    it "read every file paths of master branch" do
      expect(master_file_paths.length).to equal(40)
    end

    it "reads full file paths of master branch" do
      expect(master_file_paths).to include("files/html/500.html")
    end

    it "dose not read submodule directory and empty directory of master branch" do
      expect(master_file_paths).not_to include("six")
    end

    it "does not include 'nil'" do
      expect(master_file_paths).not_to include(nil)
    end

    it "returns empty array when not existed branch" do
      expect(not_existed_branch.length).to equal(0)
    end
  end

  describe "#copy_gitattributes" do
    let(:attributes_path) { File.join(SEED_STORAGE_PATH, TEST_REPO_PATH, 'info/attributes') }

    it "raises an error with invalid ref" do
      expect { repository.copy_gitattributes("invalid") }.to raise_error(Gitlab::Git::Repository::InvalidRef)
    end

    context "with no .gitattrbutes" do
      before(:each) do
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with .gitattrbutes" do
      before(:each) do
        repository.copy_gitattributes("gitattributes")
      end

      it "has an info/attributes" do
        expect(File.exist?(attributes_path)).to be_truthy
      end

      it "has the same content in info/attributes as .gitattributes" do
        contents = File.open(attributes_path, "rb") { |f| f.read }
        expect(contents).to eq("*.md binary\n")
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with updated .gitattrbutes" do
      before(:each) do
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

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
    end

    context "with no .gitattrbutes in HEAD but with previous info/attributes" do
      before(:each) do
        repository.copy_gitattributes("gitattributes")
        repository.copy_gitattributes("master")
      end

      it "does not have an info/attributes" do
        expect(File.exist?(attributes_path)).to be_falsey
      end

      after(:each) do
        FileUtils.rm_rf(attributes_path)
      end
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
    before(:all) do
      @repo = Gitlab::Git::Repository.new('default', File.join(TEST_MUTABLE_REPO_PATH, '.git'))
    end

    after(:all) do
      FileUtils.rm_rf(TEST_MUTABLE_REPO_PATH)
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
          { value: 7.9, label: "HTML", color: "#e44b23", highlight: "#e44b23" },
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

    context 'with rugged', skip_gitaly_mock: true do
      it_behaves_like 'languages'
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
end
