# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repository do
  include RepoHelpers
  include GitHelpers

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
      storage_exceptions = [Gitlab::Git::CommandError, GRPC::Unavailable]
      known_exception = storage_exceptions.select { |e| exception.is_a?(e) }

      expect(known_exception).not_to be_nil
    end
  end

  describe '#branch_names_contains' do
    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }

    subject { repository.branch_names_contains(sample_commit.id) }

    it { is_expected.to include('master') }
    it { is_expected.not_to include('feature') }
    it { is_expected.not_to include('fix') }

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error do
          broken_repository.branch_names_contains(sample_commit.id)
        end
      end
    end
  end

  describe '#tag_names_contains' do
    subject { repository.tag_names_contains(sample_commit.id) }

    it { is_expected.to include('v1.1.0') }
    it { is_expected.not_to include('v1.0.0') }
  end

  describe 'tags_sorted_by' do
    let(:tags_to_compare) { %w[v1.0.0 v1.1.0] }

    context 'name_desc' do
      subject { repository.tags_sorted_by('name_desc').map(&:name) & tags_to_compare }

      it { is_expected.to eq(['v1.1.0', 'v1.0.0']) }
    end

    context 'name_asc' do
      subject { repository.tags_sorted_by('name_asc').map(&:name) & tags_to_compare }

      it { is_expected.to eq(['v1.0.0', 'v1.1.0']) }
    end

    context 'updated' do
      let(:tag_a) { repository.find_tag('v1.0.0') }
      let(:tag_b) { repository.find_tag('v1.1.0') }

      context 'desc' do
        subject { repository.tags_sorted_by('updated_desc').map(&:name) }

        before do
          double_first = double(committed_date: Time.current)
          double_last = double(committed_date: Time.current - 1.second)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_first)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_last)
          allow(repository).to receive(:tags).and_return([tag_a, tag_b])
        end

        it { is_expected.to eq(['v1.0.0', 'v1.1.0']) }
      end

      context 'asc' do
        subject { repository.tags_sorted_by('updated_asc').map(&:name) }

        before do
          double_first = double(committed_date: Time.current - 1.second)
          double_last = double(committed_date: Time.current)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_last)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_first)
          allow(repository).to receive(:tags).and_return([tag_a, tag_b])
        end

        it { is_expected.to eq(['v1.1.0', 'v1.0.0']) }
      end

      context 'annotated tag pointing to a blob' do
        let(:annotated_tag_name) { 'annotated-tag' }

        subject { repository.tags_sorted_by('updated_asc').map(&:name) & (tags_to_compare + [annotated_tag_name]) }

        before do
          options = { message: 'test tag message\n',
                      tagger: { name: 'John Smith', email: 'john@gmail.com' } }

          rugged_repo(repository).tags.create(annotated_tag_name, 'a48e4fc218069f68ef2e769dd8dfea3991362175', **options)

          double_first = double(committed_date: Time.current - 1.second)
          double_last = double(committed_date: Time.current)

          allow(tag_a).to receive(:dereferenced_target).and_return(double_last)
          allow(tag_b).to receive(:dereferenced_target).and_return(double_first)
        end

        it { is_expected.to eq(['v1.1.0', 'v1.0.0', annotated_tag_name]) }

        after do
          rugged_repo(repository).tags.delete(annotated_tag_name)
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

  describe '#search_branch_names' do
    subject(:search_branch_names) { repository.search_branch_names('conflict-*') }

    it 'returns matching branch names' do
      expect(search_branch_names).to contain_exactly(
        'conflict-binary-file',
        'conflict-resolvable',
        'conflict-contains-conflict-markers',
        'conflict-missing-side',
        'conflict-start',
        'conflict-non-utf8',
        'conflict-too-large'
      )
    end
  end

  describe '#list_last_commits_for_tree' do
    let(:path_to_commit) do
      {
        "encoding" => "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        "files" => "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
        ".gitignore" => "c1acaa58bbcbc3eafe538cb8274ba387047b69f8",
        ".gitmodules" => "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9",
        "CHANGELOG" => "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        "CONTRIBUTING.md" => "6d394385cf567f80a8fd85055db1ab4c5295806f",
        "Gemfile.zip" => "ae73cb07c9eeaf35924a10f713b364d32b2dd34f",
        "LICENSE" => "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
        "MAINTENANCE.md" => "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        "PROCESS.md" => "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        "README.md" => "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
        "VERSION" => "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        "gitlab-shell" => "6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9",
        "six" => "cfe32cf61b73a0d5e9f13e774abde7ff789b1660"
      }
    end

    subject { repository.list_last_commits_for_tree(sample_commit.id, '.').id }

    it 'returns the last commits for every entry in the current path' do
      result = repository.list_last_commits_for_tree(sample_commit.id, '.')

      result.each do |key, value|
        result[key] = value.id
      end

      expect(result).to include(path_to_commit)
    end

    it 'returns the last commits for every entry in the current path starting from the offset' do
      result = repository.list_last_commits_for_tree(sample_commit.id, '.', offset: path_to_commit.size - 1)

      expect(result.size).to eq(1)
    end

    it 'returns a limited number of last commits for every entry in the current path starting from the offset' do
      result = repository.list_last_commits_for_tree(sample_commit.id, '.', limit: 1)

      expect(result.size).to eq(1)
    end

    it 'returns an empty hash when offset is out of bounds' do
      result = repository.list_last_commits_for_tree(sample_commit.id, '.', offset: path_to_commit.size)

      expect(result.size).to eq(0)
    end

    context 'with a commit with invalid UTF-8 path' do
      def create_commit_with_invalid_utf8_path
        rugged = rugged_repo(repository)
        blob_id = Rugged::Blob.from_buffer(rugged, "some contents")
        tree_builder = Rugged::Tree::Builder.new(rugged)
        tree_builder.insert({ oid: blob_id, name: "hello\x80world", filemode: 0100644 })
        tree_id = tree_builder.write
        user = { email: "jcai@gitlab.com", time: Time.current.to_time, name: "John Cai" }

        Rugged::Commit.create(rugged, message: 'some commit message', parents: [rugged.head.target.oid], tree: tree_id, committer: user, author: user)
      end

      it 'does not raise an error' do
        commit = create_commit_with_invalid_utf8_path

        expect { repository.list_last_commits_for_tree(commit, '.', offset: 0) }.not_to raise_error
      end
    end
  end

  describe '#last_commit_for_path' do
    subject { repository.last_commit_for_path(sample_commit.id, '.gitignore').id }

    it { is_expected.to eq('c1acaa58bbcbc3eafe538cb8274ba387047b69f8') }

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error do
          broken_repository.last_commit_id_for_path(sample_commit.id, '.gitignore')
        end
      end
    end

    context 'with filename with pathspec characters' do
      let(:filename) { ':wq' }
      let(:newrev) { project.repository.commit('master').sha }

      before do
        create_file_in_repo(project, 'master', 'master', filename, 'Test file')
      end

      subject { repository.last_commit_for_path('master', filename, literal_pathspec: true).id }

      it 'returns a commit SHA' do
        expect(subject).to eq(newrev)
      end
    end
  end

  describe '#last_commit_id_for_path' do
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

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error do
          broken_repository.last_commit_for_path(sample_commit.id, '.gitignore').id
        end
      end
    end

    context 'with filename with pathspec characters' do
      let(:filename) { ':wq' }
      let(:newrev) { project.repository.commit('master').sha }

      before do
        create_file_in_repo(project, 'master', 'master', filename, 'Test file')
      end

      subject { repository.last_commit_id_for_path('master', filename, literal_pathspec: true) }

      it 'returns a commit SHA' do
        expect(subject).to eq(newrev)
      end
    end
  end

  describe '#commits' do
    context 'when neither the all flag nor a ref are specified' do
      it 'returns every commit from default branch' do
        expect(repository.commits(nil, limit: 60).size).to eq(37)
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

    context "when 'author' is set" do
      it "returns commits from that author" do
        commit = repository.commits(nil, limit: 1).first
        known_author = "#{commit.author_name} <#{commit.author_email}>"

        expect(repository.commits(nil, author: known_author, limit: 1)).not_to be_empty
      end

      it "doesn't returns commits from an unknown author" do
        unknown_author = "The Man With No Name <zapp@brannigan.com>"

        expect(repository.commits(nil, author: unknown_author, limit: 1)).to be_empty
      end
    end

    context "when 'all' flag is set" do
      it 'returns every commit from the repository' do
        expect(repository.commits(nil, all: true, limit: 60).size).to eq(60)
      end
    end

    context "when 'order' flag is set" do
      it 'passes order option to perform the query' do
        expect(Gitlab::Git::Commit).to receive(:where).with(a_hash_including(order: 'topo')).and_call_original

        repository.commits('master', limit: 1, order: 'topo')
      end
    end
  end

  describe '#new_commits' do
    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }

    subject { repository.new_commits(rev) }

    context 'when there are no new commits' do
      let(:rev) { repository.commit.id }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when new commits are found' do
      let(:branch) { 'orphaned-branch' }
      let!(:rev) { repository.commit(branch).id }

      it 'returns the commits' do
        repository.delete_branch(branch)

        expect(subject).not_to be_empty
        expect(subject).to all( be_a(::Commit) )
        expect(subject.size).to eq(1)
      end
    end
  end

  describe '#commits_by' do
    let_it_be(:project) { create(:project, :repository) }

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
        ['deadbeef'] + TestEnv::BRANCH_SHA.each_value.first(10)
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

  describe '#find_commits_by_message' do
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

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error { broken_repository.find_commits_by_message('s') }
      end
    end
  end

  describe '#blob_at' do
    context 'blank sha' do
      subject { repository.blob_at(Gitlab::Git::BLANK_SHA, '.gitignore') }

      it { is_expected.to be_nil }
    end

    context 'regular blob' do
      subject { repository.blob_at(repository.head_commit.sha, '.gitignore') }

      it { is_expected.to be_an_instance_of(::Blob) }
    end

    context 'readme blob not on HEAD' do
      subject { repository.blob_at(repository.find_branch('feature').target, 'README.md') }

      it { is_expected.to be_an_instance_of(::Blob) }
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

    context 'non merged branch' do
      subject { repository.merged_to_root_ref?('fix') }

      it { is_expected.to be_falsey }
    end

    context 'non existent branch' do
      subject { repository.merged_to_root_ref?('non_existent_branch') }

      it { is_expected.to be_nil }
    end
  end

  describe "#root_ref_sha" do
    let(:commit) { double("commit", sha: "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3") }

    subject { repository.root_ref_sha }

    before do
      allow(repository).to receive(:commit).with(repository.root_ref) { commit }
    end

    it { is_expected.to eq(commit.sha) }
  end

  describe "#merged_branch_names", :clean_gitlab_redis_cache do
    subject { repository.merged_branch_names(branch_names) }

    let(:branch_names) { %w(test beep boop definitely_merged) }
    let(:already_merged) { Set.new(["definitely_merged"]) }

    let(:write_hash) do
      {
        "test" => Gitlab::Redis::Boolean.new(false).to_s,
        "beep" => Gitlab::Redis::Boolean.new(false).to_s,
        "boop" => Gitlab::Redis::Boolean.new(false).to_s,
        "definitely_merged" => Gitlab::Redis::Boolean.new(true).to_s
      }
    end

    let(:read_hash) do
      {
        "test" => Gitlab::Redis::Boolean.new(false).to_s,
        "beep" => Gitlab::Redis::Boolean.new(false).to_s,
        "boop" => Gitlab::Redis::Boolean.new(false).to_s,
        "definitely_merged" => Gitlab::Redis::Boolean.new(true).to_s
      }
    end

    let(:cache) { repository.send(:redis_hash_cache) }
    let(:cache_key) { cache.cache_key(:merged_branch_names) }

    before do
      allow(repository.raw_repository).to receive(:merged_branch_names).with(branch_names).and_return(already_merged)
    end

    it { is_expected.to eq(already_merged) }
    it { is_expected.to be_a(Set) }

    describe "cache expiry" do
      before do
        allow(cache).to receive(:delete).with(anything)
      end

      it "is expired when the branches caches are expired" do
        expect(cache).to receive(:delete) do |*args|
          expect(args).to include(:merged_branch_names)
        end

        repository.expire_branches_cache
      end

      it "is expired when the repository caches are expired" do
        expect(cache).to receive(:delete) do |*args|
          expect(args).to include(:merged_branch_names)
        end

        repository.expire_all_method_caches
      end
    end

    context "cache is empty" do
      before do
        cache.delete(:merged_branch_names)
      end

      it { is_expected.to eq(already_merged) }

      describe "cache values" do
        it "writes the values to redis" do
          expect(cache).to receive(:write).with(:merged_branch_names, write_hash)

          subject
        end

        it "matches the supplied hash" do
          subject

          expect(cache.read_members(:merged_branch_names, branch_names)).to eq(read_hash)
        end
      end
    end

    context "cache is not empty" do
      before do
        cache.write(:merged_branch_names, write_hash)
      end

      it { is_expected.to eq(already_merged) }

      it "doesn't fetch from the disk" do
        expect(repository.raw_repository).not_to receive(:merged_branch_names)

        subject
      end
    end

    context "cache is partially complete" do
      before do
        allow(repository.raw_repository).to receive(:merged_branch_names).with(["boop"]).and_return([])
        hash = write_hash.except("boop")
        cache.write(:merged_branch_names, hash)
      end

      it { is_expected.to eq(already_merged) }

      it "does fetch from the disk" do
        expect(repository.raw_repository).to receive(:merged_branch_names).with(["boop"])

        subject
      end
    end

    context "requested branches array is empty" do
      let(:branch_names) { [] }

      it { is_expected.to eq(already_merged) }
    end
  end

  describe '#can_be_merged?' do
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

    context 'submodule changes that confuse rugged' do
      subject { repository.can_be_merged?('update-gitlab-shell-v-6-0-1', 'update-gitlab-shell-v-6-0-3') }

      it { is_expected.to be_falsey }
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

    context 'when ref is not specified' do
      it 'is using a root ref' do
        expect(repository).to receive(:find_commit).with('master')

        repository.commit
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

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
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

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error { broken_repository.search_files_by_name('files', 'master') }
      end
    end
  end

  describe '#search_files_by_wildcard_path' do
    let(:ref) { 'master' }

    subject(:result) { repository.search_files_by_wildcard_path(path, ref) }

    context 'when specifying a normal path' do
      let(:path) { 'files/images/logo-black.png' }

      it 'returns the path' do
        expect(result).to eq(['files/images/logo-black.png'])
      end
    end

    context 'when specifying a wildcard path' do
      let(:path) { '*.md' }

      it 'returns files matching the path in the root folder' do
        expect(result).to contain_exactly('CONTRIBUTING.md',
                                          'MAINTENANCE.md',
                                          'PROCESS.md',
                                          'README.md')
      end
    end

    context 'when specifying a wildcard path for all' do
      let(:path) { '**.md' }

      it 'returns all matching files in all folders' do
        expect(result).to contain_exactly('CONTRIBUTING.md',
                                          'MAINTENANCE.md',
                                          'PROCESS.md',
                                          'README.md',
                                          'files/markdown/ruby-style-guide.md',
                                          'with space/README.md')
      end
    end

    context 'when specifying a path to subfolders using two asterisks and a slash' do
      let(:path) { 'files/**/*.md' }

      it 'returns all files matching the path' do
        expect(result).to contain_exactly('files/markdown/ruby-style-guide.md')
      end
    end

    context 'when specifying a wildcard path to subfolder with just two asterisks' do
      let(:path) { 'files/**.md' }

      it 'returns all files in the matching path' do
        expect(result).to contain_exactly('files/markdown/ruby-style-guide.md')
      end
    end

    context 'when specifying a wildcard path to subfolder with one asterisk' do
      let(:path) { 'files/*/*.md' }

      it 'returns all files in the matching path' do
        expect(result).to contain_exactly('files/markdown/ruby-style-guide.md')
      end
    end

    context 'when specifying a wildcard path for an unknown number of subfolder levels' do
      let(:path) { '**/*.rb' }

      it 'returns all matched files in all subfolders' do
        expect(result).to contain_exactly('encoding/russian.rb',
                                          'files/ruby/popen.rb',
                                          'files/ruby/regex.rb',
                                          'files/ruby/version_info.rb')
      end
    end

    context 'when specifying a wildcard path to one level of subfolders' do
      let(:path) { '*/*.rb' }

      it 'returns all matched files in one subfolder' do
        expect(result).to contain_exactly('encoding/russian.rb')
      end
    end

    context 'when sending regexp' do
      let(:path) { '.*\.rb' }

      it 'ignores the regexp and returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'when sending another ref' do
      let(:path) { 'files' }
      let(:ref) { 'other-branch' }

      it 'returns an empty array' do
        expect(result).to eq([])
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
        expect(Gitlab::AppLogger).to receive(:info).with("Remove remote job failed to create for #{project.id} with remote name joe.")

        expect(repository.async_remove_remote('joe')).to be_nil
      end
    end
  end

  describe '#fetch_as_mirror' do
    let(:url) { "http://example.com" }

    context 'when :fetch_remote_params is enabled' do
      let(:remote_name) { "remote-name" }

      before do
        stub_feature_flags(fetch_remote_params: true)
      end

      it 'fetches the URL without creating a remote' do
        expect(repository).not_to receive(:add_remote)
        expect(repository)
          .to receive(:fetch_remote)
          .with(remote_name, url: url, forced: false, prune: true, refmap: :all_refs)
          .and_return(nil)

        repository.fetch_as_mirror(url, remote_name: remote_name)
      end
    end

    context 'when :fetch_remote_params is disabled' do
      before do
        stub_feature_flags(fetch_remote_params: false)
      end

      shared_examples 'a fetch' do
        it 'adds and fetches a remote' do
          expect(repository)
            .to receive(:add_remote)
            .with(expected_remote, url, mirror_refmap: :all_refs)
            .and_return(nil)
          expect(repository)
            .to receive(:fetch_remote)
            .with(expected_remote, forced: false, prune: true)
            .and_return(nil)

          repository.fetch_as_mirror(url, remote_name: remote_name)
        end
      end

      context 'with temporary remote' do
        let(:remote_name) { nil }
        let(:expected_remote_suffix) { "123456" }
        let(:expected_remote) { "tmp-#{expected_remote_suffix}" }

        before do
          expect(repository)
            .to receive(:async_remove_remote).with(expected_remote).and_return(nil)
          allow(SecureRandom).to receive(:hex).and_return(expected_remote_suffix)
        end

        it_behaves_like 'a fetch'
      end

      context 'with remote name' do
        let(:remote_name) { "foo" }
        let(:expected_remote) { "foo" }

        it_behaves_like 'a fetch'
      end
    end
  end

  describe '#fetch_ref' do
    let(:broken_repository) { create(:project, :broken_storage).repository }

    describe 'when storage is broken', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error do
          broken_repository.fetch_ref(broken_repository, source_ref: '1', target_ref: '2')
        end
      end
    end
  end

  describe '#get_raw_changes' do
    context 'with non-UTF8 bytes in paths' do
      let(:old_rev) { 'd0888d297eadcd7a345427915c309413b1231e65' }
      let(:new_rev) { '19950f03c765f7ac8723a73a0599764095f52fc0' }
      let(:changes) { repository.raw_changes_between(old_rev, new_rev) }

      it 'returns the changes' do
        expect { changes }.not_to raise_error
        expect(changes.first.new_path.bytes).to eq("hello\x80world".bytes)
      end
    end
  end

  describe '#create_ref' do
    it 'redirects the call to write_ref' do
      ref = '1'
      ref_path = '2'

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

    it 'returns other when the content is not recognizable' do
      repository.create_file(user, 'LICENSE', 'Gitlab B.V.',
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license_key).to eq('other')
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

    it 'returns other when the content is not recognizable' do
      license = Licensee::License.new('other')
      repository.create_file(user, 'LICENSE', 'Gitlab B.V.',
        message: 'Add LICENSE', branch_name: 'master')

      expect(repository.license).to eq(license)
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

  describe '#ambiguous_ref?' do
    let(:ref) { 'ref' }

    subject { repository.ambiguous_ref?(ref) }

    context 'when ref is ambiguous' do
      before do
        repository.add_tag(project.creator, ref, 'master')
        repository.add_branch(project.creator, ref, 'master')
      end

      it 'is true' do
        is_expected.to eq(true)
      end
    end

    context 'when ref is not ambiguous' do
      before do
        repository.add_tag(project.creator, ref, 'master')
      end

      it 'is false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#has_ambiguous_refs?' do
    using RSpec::Parameterized::TableSyntax

    where(:branch_names, :tag_names, :result) do
      nil | nil | false
      %w() | %w() | false
      %w(a b) | %w() | false
      %w() | %w(c d) | false
      %w(a b) | %w(c d) | false
      %w(a/b) | %w(c/d) | false
      %w(a b) | %w(c d a/z) | true
      %w(a b c/z) | %w(c d) | true
      %w(a/b/z) | %w(a/b) | false # we only consider refs ambiguous before the first slash
      %w(a/b/z) | %w(a/b a) | true
      %w(ab) | %w(abc/d a b) | false
    end

    with_them do
      it do
        allow(repository).to receive(:branch_names).and_return(branch_names)
        allow(repository).to receive(:tag_names).and_return(tag_names)

        expect(repository.has_ambiguous_refs?).to eq(result)
      end
    end
  end

  describe '#expand_ref' do
    let(:ref) { 'ref' }

    subject { repository.expand_ref(ref) }

    context 'when ref is not tag or branch name' do
      let(:ref) { 'refs/heads/master' }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when ref is tag name' do
      before do
        repository.add_tag(project.creator, ref, 'master')
      end

      it 'returns the tag ref' do
        is_expected.to eq("refs/tags/#{ref}")
      end
    end

    context 'when ref is branch name' do
      before do
        repository.add_branch(project.creator, ref, 'master')
      end

      it 'returns the branch ref' do
        is_expected.to eq("refs/heads/#{ref}")
      end
    end
  end

  describe '#add_branch' do
    let(:branch_name) { 'new_feature' }
    let(:target) { 'master' }

    subject { repository.add_branch(user, branch_name, target) }

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

  shared_examples 'asymmetric cached method' do |method|
    context 'asymmetric caching', :use_clean_rails_memory_store_caching, :request_store do
      let(:cache) { repository.send(:cache) }
      let(:request_store_cache) { repository.send(:request_store_cache) }

      context 'when it returns true' do
        before do
          expect(repository.raw_repository).to receive(method).once.and_return(true)
        end

        it 'caches the output in RequestStore' do
          expect do
            repository.send(method)
          end.to change { request_store_cache.read(method) }.from(nil).to(true)
        end

        it 'caches the output in RepositoryCache' do
          expect do
            repository.send(method)
          end.to change { cache.read(method) }.from(nil).to(true)
        end
      end

      context 'when it returns false' do
        before do
          expect(repository.raw_repository).to receive(method).once.and_return(false)
        end

        it 'caches the output in RequestStore' do
          expect do
            repository.send(method)
          end.to change { request_store_cache.read(method) }.from(nil).to(false)
        end

        it 'does NOT cache the output in RepositoryCache' do
          expect do
            repository.send(method)
          end.not_to change { cache.read(method) }.from(nil)
        end
      end
    end
  end

  describe '#exists?' do
    it 'returns true when a repository exists' do
      expect(repository.exists?).to be(true)
    end

    it 'returns false if no full path can be constructed' do
      allow(repository).to receive(:full_path).and_return(nil)

      expect(repository.exists?).to be(false)
    end

    context 'with broken storage', :broken_storage do
      it 'raises a storage error' do
        expect_to_raise_storage_error { broken_repository.exists? }
      end
    end

    it_behaves_like 'asymmetric cached method', :exists?
  end

  describe '#has_visible_content?' do
    it 'delegates to raw_repository when true' do
      expect(repository.raw_repository).to receive(:has_visible_content?)
        .and_return(true)

      expect(repository.has_visible_content?).to eq(true)
    end

    it 'delegates to raw_repository when false' do
      expect(repository.raw_repository).to receive(:has_visible_content?)
        .and_return(false)

      expect(repository.has_visible_content?).to eq(false)
    end

    it_behaves_like 'asymmetric cached method', :has_visible_content?
  end

  describe '#branch_exists?' do
    let(:branch) { repository.root_ref }

    subject { repository.branch_exists?(branch) }

    it 'delegates to branch_names when the cache is empty' do
      repository.expire_branches_cache

      expect(repository).to receive(:branch_names).and_call_original
      is_expected.to eq(true)
    end

    it 'uses redis set caching when the cache is filled' do
      repository.branch_names # ensure the branch name cache is filled

      expect(repository)
        .to receive(:branch_names_include?)
        .with(branch)
        .and_call_original

      is_expected.to eq(true)
    end
  end

  describe '#tag_exists?' do
    let(:tag) { repository.tags.first.name }

    subject { repository.tag_exists?(tag) }

    it 'delegates to tag_names when the cache is empty' do
      repository.expire_tags_cache

      expect(repository).to receive(:tag_names).and_call_original
      is_expected.to eq(true)
    end

    it 'uses redis set caching when the cache is filled' do
      repository.tag_names # ensure the tag name cache is filled

      expect(repository)
        .to receive(:tag_names_include?)
        .with(tag)
        .and_call_original

      is_expected.to eq(true)
    end
  end

  describe '#branch_names', :clean_gitlab_redis_cache do
    let(:fake_branch_names) { ['foobar'] }

    it 'gets cached across Repository instances' do
      allow(repository.raw_repository).to receive(:branch_names).once.and_return(fake_branch_names)

      expect(repository.branch_names).to match_array(fake_branch_names)

      fresh_repository = Project.find(project.id).repository
      expect(fresh_repository.object_id).not_to eq(repository.object_id)

      expect(fresh_repository.raw_repository).not_to receive(:branch_names)
      expect(fresh_repository.branch_names).to match_array(fake_branch_names)
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

  describe '#blobs_at' do
    let(:empty_repository) { create(:project_empty_repo).repository }

    it 'returns empty array for an empty repository' do
      expect(empty_repository.blobs_at(%w[master foobar])).to eq([])
    end

    it 'returns blob array for a non-empty repository' do
      repository.create_file(User.last, 'foobar', 'CONTENT', message: 'message', branch_name: 'master')

      blobs = repository.blobs_at([%w[master foobar]])

      expect(blobs.first.name).to eq('foobar')
      expect(blobs.size).to eq(1)
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

    it 'returns nil if the repository does not exist' do
      repository = create(:project).repository

      expect(repository).not_to be_exists
      expect(repository.root_ref).to be_nil
    end

    it_behaves_like 'asymmetric cached method', :root_ref
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

    it 'expires the memoized repository cache' do
      allow(repository.raw_repository).to receive(:expire_has_local_branches_cache).and_call_original

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

    def merge(repository, user, merge_request, message)
      repository.merge(user, merge_request.diff_head_sha, merge_request, message)
    end
  end

  describe '#merge_to_ref' do
    let(:merge_request) do
      create(:merge_request, source_branch: 'feature',
                             target_branch: 'master',
                             source_project: project)
    end

    it 'writes merge of source SHA and first parent ref to MR merge_ref_path' do
      merge_commit_id =
        repository.merge_to_ref(user,
          source_sha: merge_request.diff_head_sha,
          branch: merge_request.target_branch,
          target_ref: merge_request.merge_ref_path,
          message: 'Custom message',
          first_parent_ref: merge_request.target_branch_ref)

      merge_commit = repository.commit(merge_commit_id)

      expect(merge_commit.message).to eq('Custom message')
      expect(merge_commit.author_name).to eq(user.name)
      expect(merge_commit.author_email).to eq(user.commit_email)
      expect(repository.blob_at(merge_commit.id, 'files/ruby/feature.rb')).to be_present
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

  describe '#rebase' do
    let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master', source_project: project) }

    shared_examples_for 'a method that can rebase successfully' do
      it 'returns the rebase commit sha' do
        rebase_commit_sha = repository.rebase(user, merge_request)
        head_sha = merge_request.source_project.repository.commit(merge_request.source_branch).sha

        expect(rebase_commit_sha).to eq(head_sha)
      end

      it 'sets the `rebase_commit_sha` for the given merge request' do
        rebase_commit_sha = repository.rebase(user, merge_request)

        expect(rebase_commit_sha).not_to be_nil
        expect(merge_request.rebase_commit_sha).to eq(rebase_commit_sha)
      end
    end

    it_behaves_like 'a method that can rebase successfully'

    it 'executes the new Gitaly RPC' do
      expect_any_instance_of(Gitlab::GitalyClient::OperationService).to receive(:rebase)

      repository.rebase(user, merge_request)
    end

    describe 'rolling back the `rebase_commit_sha`' do
      let(:new_sha) { Digest::SHA1.hexdigest('foo') }

      it 'does not rollback when there are no errors' do
        second_response = double(pre_receive_error: nil, git_error: nil)
        mock_gitaly(second_response)

        repository.rebase(user, merge_request)

        expect(merge_request.reload.rebase_commit_sha).to eq(new_sha)
      end

      it 'does rollback when a PreReceiveError is encountered in the second step' do
        second_response = double(pre_receive_error: 'my_error', git_error: nil)
        mock_gitaly(second_response)

        expect do
          repository.rebase(user, merge_request)
        end.to raise_error(Gitlab::Git::PreReceiveError)

        expect(merge_request.reload.rebase_commit_sha).to be_nil
      end

      it 'does rollback when a GitError is encountered in the second step' do
        second_response = double(pre_receive_error: nil, git_error: 'git error')
        mock_gitaly(second_response)

        expect do
          repository.rebase(user, merge_request)
        end.to raise_error(Gitlab::Git::Repository::GitError)

        expect(merge_request.reload.rebase_commit_sha).to be_nil
      end

      def mock_gitaly(second_response)
        responses = [
          double(rebase_sha: new_sha).as_null_object,
          second_response
        ]

        expect_any_instance_of(
          Gitaly::OperationService::Stub
        ).to receive(:user_rebase_confirmable).and_return(responses.each)
      end
    end
  end

  describe '#revert' do
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

  describe '#cherry_pick' do
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
    it 'flushes the method caches' do
      expect(repository).to receive(:expire_method_caches).with([
        :size,
        :commit_count,
        :readme_path,
        :contribution_guide,
        :changelog,
        :license_blob,
        :license_key,
        :gitignore,
        :gitlab_ci_yml,
        :branch_names,
        :tag_names,
        :branch_count,
        :tag_count,
        :avatar,
        :exists?,
        :root_ref,
        :merged_branch_names,
        :has_visible_content?,
        :issue_template_names_hash,
        :merge_request_template_names_hash,
        :user_defined_metrics_dashboard_paths,
        :xcode_project?,
        :has_ambiguous_refs?
      ])

      repository.after_change_head
    end
  end

  describe '#expires_caches_for_tags' do
    it 'flushes the cache' do
      expect(repository).to receive(:expire_statistics_caches)
      expect(repository).to receive(:expire_emptiness_caches)
      expect(repository).to receive(:expire_tags_cache)

      repository.expire_caches_for_tags
    end
  end

  describe '#before_push_tag' do
    it 'logs an event' do
      expect(repository).not_to receive(:expire_statistics_caches)
      expect(repository).not_to receive(:expire_emptiness_caches)
      expect(repository).not_to receive(:expire_tags_cache)
      expect(repository).to receive(:repository_event).with(:push_tag)

      repository.before_push_tag
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

    it 'does not expire the branch caches when specified' do
      expect(repository).not_to receive(:expire_branches_cache)

      repository.after_create_branch(expire_cache: false)
    end
  end

  describe '#after_remove_branch' do
    it 'expires the branch caches' do
      expect(repository).to receive(:expire_branches_cache)

      repository.after_remove_branch
    end

    it 'does not expire the branch caches when specified' do
      expect(repository).not_to receive(:expire_branches_cache)

      repository.after_remove_branch(expire_cache: false)
    end
  end

  describe '#lookup' do
    before do
      allow(repository.raw_repository).to receive(:lookup).and_return('interesting_blob')
    end

    it 'uses the lookup cache' do
      2.times.each { repository.lookup('sha1') }

      expect(repository.raw_repository).to have_received(:lookup).once
    end

    it 'returns the correct value' do
      expect(repository.lookup('sha1')).to eq('interesting_blob')
    end
  end

  describe '#after_create' do
    it 'calls expire_status_cache' do
      expect(repository).to receive(:expire_status_cache)

      repository.after_create
    end

    it 'logs an event' do
      expect(repository).to receive(:repository_event).with(:create_repository)

      repository.after_create
    end
  end

  describe '#expire_status_cache' do
    it 'flushes the exists cache' do
      expect(repository).to receive(:expire_exists_cache)

      repository.expire_status_cache
    end

    it 'flushes the root ref cache' do
      expect(repository).to receive(:expire_root_ref_cache)

      repository.expire_status_cache
    end

    it 'flushes the emptiness caches' do
      expect(repository).to receive(:expire_emptiness_caches)

      repository.expire_status_cache
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

      rugged_count = rugged_repo(repository).branches.count

      expect(repository.branch_count).to eq(rugged_count)
    end
  end

  describe '#tag_count' do
    it 'returns the number of tags' do
      expect(repository.tag_count).to be_an(Integer)

      rugged_count = rugged_repo(repository).tags.count

      expect(repository.tag_count).to eq(rugged_count)
    end
  end

  describe '#expire_branches_cache' do
    it 'expires the cache' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(branch_names merged_branch_names branch_count has_visible_content? has_ambiguous_refs?))
        .and_call_original

      repository.expire_branches_cache
    end
  end

  describe '#expire_tags_cache' do
    it 'expires the cache' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(tag_names tag_count has_ambiguous_refs?))
        .and_call_original

      repository.expire_tags_cache
    end
  end

  describe '#add_tag' do
    let(:user) { build_stubbed(:user) }

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

  describe '#rm_branch' do
    it 'removes a branch' do
      expect(repository).to receive(:before_remove_branch)
      expect(repository).to receive(:after_remove_branch)

      repository.rm_branch(user, 'feature')
    end

    context 'when pre hooks failed' do
      before do
        allow_any_instance_of(Gitlab::GitalyClient::OperationService)
          .to receive(:user_delete_branch).and_raise(Gitlab::Git::PreReceiveError)
      end

      it 'gets an error and does not delete the branch' do
        expect do
          repository.rm_branch(user, 'feature')
        end.to raise_error(Gitlab::Git::PreReceiveError)

        expect(repository.find_branch('feature')).not_to be_nil
      end
    end
  end

  describe '#rm_tag' do
    it 'removes a tag' do
      expect(repository).to receive(:before_remove_tag)

      repository.rm_tag(build_stubbed(:user), 'v1.1.0')

      expect(repository.find_tag('v1.1.0')).to be_nil
    end
  end

  describe '#avatar' do
    it 'returns nil if repo does not exist' do
      allow(repository).to receive(:root_ref).and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository.avatar).to be_nil
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
    let(:request_store_cache) { repository.send(:request_store_cache) }

    it 'expires the cache' do
      expect(cache).to receive(:expire).with(:exists?)

      repository.expire_exists_cache
    end

    it 'expires the request store cache', :request_store do
      expect(request_store_cache).to receive(:expire).with(:exists?)

      repository.expire_exists_cache
    end
  end

  describe '#xcode_project?' do
    before do
      allow(repository).to receive(:tree).with(:head).and_return(double(:tree, trees: [tree]))
    end

    context 'when the root contains a *.xcodeproj directory' do
      let(:tree) { double(:tree, path: 'Foo.xcodeproj') }

      it 'returns true' do
        expect(repository.xcode_project?).to be_truthy
      end
    end

    context 'when the root contains a *.xcworkspace directory' do
      let(:tree) { double(:tree, path: 'Foo.xcworkspace') }

      it 'returns true' do
        expect(repository.xcode_project?).to be_truthy
      end
    end

    context 'when the root contains no Xcode config directory' do
      let(:tree) { double(:tree, path: 'Foo') }

      it 'returns false' do
        expect(repository.xcode_project?).to be_falsey
      end
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

  describe '#readme', :use_clean_rails_memory_store_caching do
    context 'with a non-existing repository' do
      let(:project) { create(:project) }

      it 'returns nil' do
        expect(repository.readme).to be_nil
      end
    end

    context 'with an existing repository' do
      context 'when no README exists' do
        let(:project) { create(:project, :empty_repo) }

        it 'returns nil' do
          expect(repository.readme).to be_nil
        end
      end
    end
  end

  describe '#readme_path', :use_clean_rails_memory_store_caching do
    context 'with a non-existing repository' do
      let(:project) { create(:project) }

      it 'returns nil' do
        expect(repository.readme_path).to be_nil
      end
    end

    context 'with an existing repository' do
      context 'when no README exists' do
        let(:project) { create(:project, :empty_repo) }

        it 'returns nil' do
          expect(repository.readme_path).to be_nil
        end
      end

      context 'when a README exists' do
        let(:project) { create(:project, :repository) }

        it 'returns the README' do
          expect(repository.readme_path).to eq("README.md")
        end

        it 'caches the response' do
          expect(repository.head_tree).to receive(:readme_path).and_call_original.once

          2.times do
            expect(repository.readme_path).to eq("README.md")
          end
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

      expect(Repository::CACHED_METHODS + Repository::MEMOIZED_CACHED_METHODS).to include(*methods)
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

  shared_examples '#tree' do
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
        expect(repository.tree('v1.1.1')).to be_an_instance_of(Tree)
      end
    end
  end

  it_behaves_like '#tree'

  describe '#tree? with Rugged enabled', :enable_rugged do
    it_behaves_like '#tree'
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

  describe '#refresh_method_caches' do
    it 'refreshes the caches of the given types' do
      expect(repository).to receive(:expire_method_caches)
        .with(%i(readme_path license_blob license_key license))

      expect(repository).to receive(:readme_path)
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

  def create_remote_branch(remote_name, branch_name, target)
    rugged = rugged_repo(repository)
    rugged.references.create("refs/remotes/#{remote_name}/#{branch_name}", target.id)
  end

  shared_examples '#ancestor?' do
    let(:commit) { repository.commit }
    let(:ancestor) { commit.parents.first }

    it 'is an ancestor' do
      expect(repository.ancestor?(ancestor.id, commit.id)).to eq(true)
    end

    it 'is not an ancestor' do
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

  describe '#ancestor? with Gitaly enabled' do
    let(:commit) { repository.commit }
    let(:ancestor) { commit.parents.first }
    let(:cache_key) { "ancestor:#{ancestor.id}:#{commit.id}" }

    it_behaves_like '#ancestor?'

    context 'caching', :request_store, :clean_gitlab_redis_cache do
      it 'only calls out to Gitaly once' do
        expect(repository.raw_repository).to receive(:ancestor?).once

        2.times { repository.ancestor?(commit.id, ancestor.id) }
      end

      it 'returns the value from the request store' do
        repository.__send__(:request_store_cache).write(cache_key, "it's apparent")

        expect(repository.ancestor?(ancestor.id, commit.id)).to eq("it's apparent")
      end

      it 'returns the value from the redis cache' do
        expect(repository.__send__(:cache)).to receive(:fetch).with(cache_key).and_return("it's apparent")

        expect(repository.ancestor?(ancestor.id, commit.id)).to eq("it's apparent")
      end
    end
  end

  describe '#ancestor? with Rugged enabled', :enable_rugged do
    it 'calls out to the Rugged implementation' do
      allow_any_instance_of(Rugged).to receive(:merge_base).with(repository.commit.id, Gitlab::Git::BLANK_SHA).and_call_original

      repository.ancestor?(repository.commit.id, Gitlab::Git::BLANK_SHA)
    end

    it_behaves_like '#ancestor?'
  end

  describe '#archive_metadata' do
    let(:ref) { 'master' }
    let(:storage_path) { '/tmp' }

    let(:prefix) { [project.path, ref].join('-') }
    let(:filename) { prefix + '.tar.gz' }

    subject(:result) { repository.archive_metadata(ref, storage_path, append_sha: false) }

    context 'with hashed storage disabled' do
      let(:project) { create(:project, :repository, :legacy_storage) }

      it 'uses the project path to generate the filename' do
        expect(result['ArchivePrefix']).to eq(prefix)
        expect(File.basename(result['ArchivePath'])).to eq(filename)
      end
    end

    context 'with hashed storage enabled' do
      it 'uses the project path to generate the filename' do
        expect(result['ArchivePrefix']).to eq(prefix)
        expect(File.basename(result['ArchivePath'])).to eq(filename)
      end
    end
  end

  describe 'commit cache' do
    let_it_be(:project) { create(:project, :repository) }

    it 'caches based on SHA' do
      # Gets the commit oid, and warms the cache
      oid = project.commit.id

      expect(Gitlab::Git::Commit).to receive(:find).once

      2.times { project.commit_by(oid: oid) }
    end

    it 'caches nil values' do
      expect(Gitlab::Git::Commit).to receive(:find).once

      2.times { project.commit_by(oid: '1' * 40) }
    end
  end

  describe '#raw_repository' do
    subject { repository.raw_repository }

    it 'returns a Gitlab::Git::Repository representation of the repository' do
      expect(subject).to be_a(Gitlab::Git::Repository)
      expect(subject.relative_path).to eq(project.disk_path + '.git')
      expect(subject.gl_repository).to eq("project-#{project.id}")
      expect(subject.gl_project_path).to eq(project.full_path)
    end

    context 'with a wiki repository' do
      let(:repository) { project.wiki.repository }

      it 'creates a Gitlab::Git::Repository with the proper attributes' do
        expect(subject).to be_a(Gitlab::Git::Repository)
        expect(subject.relative_path).to eq(project.disk_path + '.wiki.git')
        expect(subject.gl_repository).to eq("wiki-#{project.id}")
        expect(subject.gl_project_path).to eq(project.wiki.full_path)
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

  describe '#merge_base' do
    let_it_be(:project) { create(:project, :repository) }

    subject(:repository) { project.repository }

    it 'only makes one gitaly call' do
      expect(Gitlab::GitalyClient).to receive(:call).once.and_call_original

      repository.merge_base('master', 'fix')
    end
  end

  describe '#create_if_not_exists' do
    let(:project) { create(:project) }
    let(:repository) { project.repository }

    it 'creates the repository if it did not exist' do
      expect { repository.create_if_not_exists }.to change { repository.exists? }.from(false).to(true)
    end

    it 'returns true' do
      expect(repository.create_if_not_exists).to eq(true)
    end

    it 'calls out to the repository client to create a repo' do
      expect(repository.raw.gitaly_repository_client).to receive(:create_repository)

      repository.create_if_not_exists
    end

    context 'it does nothing if the repository already existed' do
      let(:project) { create(:project, :repository) }

      it 'does nothing if the repository already existed' do
        expect(repository.raw.gitaly_repository_client).not_to receive(:create_repository)

        repository.create_if_not_exists
      end

      it 'returns nil' do
        expect(repository.create_if_not_exists).to be_nil
      end
    end

    context 'when the repository exists but the cache is not up to date' do
      let(:project) { create(:project, :repository) }

      it 'does not raise errors' do
        allow(repository).to receive(:exists?).and_return(false)
        expect(repository.raw).to receive(:create_repository).and_call_original

        expect { repository.create_if_not_exists }.not_to raise_error
      end

      it 'returns nil' do
        expect(repository.create_if_not_exists).to be_nil
      end
    end
  end

  describe '#create_from_bundle' do
    let(:project) { create(:project) }
    let(:repository) { project.repository }
    let(:valid_bundle_path) { File.join(Dir.tmpdir, "repo-#{SecureRandom.hex}.bundle") }
    let(:raw_repository) { repository.raw }

    before do
      allow(raw_repository).to receive(:create_from_bundle).and_return({})
    end

    after do
      FileUtils.rm_rf(valid_bundle_path)
    end

    it 'calls out to the raw_repository to create a repo from bundle' do
      expect(raw_repository).to receive(:create_from_bundle)

      repository.create_from_bundle(valid_bundle_path)
    end

    it 'calls after_create' do
      expect(repository).to receive(:after_create)

      repository.create_from_bundle(valid_bundle_path)
    end

    context 'when exception is raised' do
      before do
        allow(raw_repository).to receive(:create_from_bundle).and_raise(::Gitlab::Git::BundleFile::InvalidBundleError)
      end

      it 'after_create is not executed' do
        expect(repository).not_to receive(:after_create)

        expect {repository.create_from_bundle(valid_bundle_path)}.to raise_error(::Gitlab::Git::BundleFile::InvalidBundleError)
      end
    end
  end

  describe "#blobs_metadata" do
    let_it_be(:project) { create(:project, :repository) }

    let(:repository) { project.repository }

    def expect_metadata_blob(thing)
      expect(thing).to be_a(Blob)
      expect(thing.data).to be_empty
    end

    it "returns blob metadata in batch for HEAD" do
      result = repository.blobs_metadata(["bar/branch-test.txt", "README.md", "does/not/exist"])

      expect_metadata_blob(result.first)
      expect_metadata_blob(result.second)
      expect(result.size).to eq(2)
    end

    it "returns blob metadata for a specified ref" do
      result = repository.blobs_metadata(["files/ruby/feature.rb"], "feature")

      expect_metadata_blob(result.first)
    end

    it "performs a single gitaly call", :request_store do
      expect { repository.blobs_metadata(["bar/branch-test.txt", "readme.txt", "does/not/exist"]) }
        .to change { Gitlab::GitalyClient.get_request_count }.by(1)
    end
  end

  describe '#project' do
    it 'returns the project for a project snippet' do
      snippet = create(:project_snippet)

      expect(snippet.repository.project).to be(snippet.project)
    end

    it 'returns nil for a personal snippet' do
      snippet = create(:personal_snippet)

      expect(snippet.repository.project).to be_nil
    end

    it 'returns the project for a project wiki' do
      wiki = create(:project_wiki)

      expect(wiki.project).to be(wiki.repository.project)
    end

    it 'returns the container if it is a project' do
      expect(repository.project).to be(project)
    end

    it 'returns nil if the container is not a project' do
      repository.container = Group.new

      expect(repository.project).to be_nil
    end
  end

  describe '#submodule_links' do
    it 'returns an instance of Gitlab::SubmoduleLinks' do
      expect(repository.submodule_links).to be_a(Gitlab::SubmoduleLinks)
    end
  end

  describe '#lfs_enabled?' do
    let_it_be(:project) { create(:project, :repository, :design_repo, lfs_enabled: true) }

    subject { repository.lfs_enabled? }

    context 'for a project repository' do
      let(:repository) { project.repository }

      it 'returns true when LFS is enabled' do
        stub_lfs_setting(enabled: true)

        is_expected.to be_truthy
      end

      it 'returns false when LFS is disabled' do
        stub_lfs_setting(enabled: false)

        is_expected.to be_falsy
      end
    end

    context 'for a project wiki repository' do
      let(:repository) { project.wiki.repository }

      it 'delegates to the project' do
        expect(project).to receive(:lfs_enabled?).and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'for a project snippet repository' do
      let(:snippet) { create(:project_snippet, project: project) }
      let(:repository) { snippet.repository }

      it 'returns false when LFS is enabled' do
        stub_lfs_setting(enabled: true)

        is_expected.to be_falsy
      end
    end

    context 'for a personal snippet repository' do
      let(:snippet) { create(:personal_snippet) }
      let(:repository) { snippet.repository }

      it 'returns false when LFS is enabled' do
        stub_lfs_setting(enabled: true)

        is_expected.to be_falsy
      end
    end

    context 'for a design repository' do
      let(:repository) { project.design_repository }

      it 'returns true when LFS is enabled' do
        stub_lfs_setting(enabled: true)

        is_expected.to be_truthy
      end

      it 'returns false when LFS is disabled' do
        stub_lfs_setting(enabled: false)

        is_expected.to be_falsy
      end
    end
  end

  describe '.pick_storage_shard', :request_store do
    before do
      storages = {
        'default' => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/repositories'),
        'picked'  => Gitlab::GitalyClient::StorageSettings.new('path' => 'tmp/tests/repositories')
      }

      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      Gitlab::CurrentSettings.current_application_settings

      update_storages({ 'picked' => 0, 'default' => 100 })
    end

    context 'when expire is false' do
      it 'does not expire existing repository storage value' do
        previous_storage = described_class.pick_storage_shard
        expect(previous_storage).to eq('default')
        expect(Gitlab::CurrentSettings).not_to receive(:expire_current_application_settings)

        update_storages({ 'picked' => 100, 'default' => 0 })

        new_storage = described_class.pick_storage_shard(expire: false)
        expect(new_storage).to eq(previous_storage)
      end
    end

    context 'when expire is true' do
      it 'expires existing repository storage value' do
        previous_storage = described_class.pick_storage_shard
        expect(previous_storage).to eq('default')
        expect(Gitlab::CurrentSettings).to receive(:expire_current_application_settings).and_call_original

        update_storages({ 'picked' => 100, 'default' => 0 })

        new_storage = described_class.pick_storage_shard(expire: true)
        expect(new_storage).to eq('picked')
      end
    end

    def update_storages(storage_hash)
      settings = ApplicationSetting.last
      settings.repository_storages_weighted = storage_hash
      settings.save!
    end
  end
end
