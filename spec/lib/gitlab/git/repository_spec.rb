# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Repository, feature_category: :source_code_management do
  include Gitlab::EncodingHelper
  include RepoHelpers
  using RSpec::Parameterized::TableSyntax

  shared_examples 'wrapping gRPC errors' do |gitaly_client_class, gitaly_client_method|
    context 'when commit is not found' do
      let(:find_commits_error) { Gitaly::FindCommitsError.new }

      before do
        allow(Gitlab::GitalyClient).to receive(:decode_detailed_error).and_return(find_commits_error)
      end

      it 'wraps gRPC not found error' do
        expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method).and_raise(GRPC::NotFound)
        expect { subject }.to raise_error(Gitlab::Git::Repository::CommitNotFound)
      end
    end

    it 'wraps gRPC unknown error' do
      expect_any_instance_of(gitaly_client_class).to receive(gitaly_client_method)
        .and_raise(GRPC::Unknown)
      expect { subject }.to raise_error(Gitlab::Git::CommandError)
    end
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository.raw }

  let(:mutable_project) { create(:project, :repository) }
  let(:mutable_repository) { mutable_project.repository.raw }
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
      expect_any_instance_of(Gitlab::GitalyClient::RefService).to receive(:default_branch_name).with(head_only: true)
      repository.root_ref(head_only: true)
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

    it 'has TestRepo::BRANCH_SHA.size elements' do
      expect(subject.size).to eq(TestEnv::BRANCH_SHA.size)
    end

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end

    it { is_expected.to include("master") }
    it { is_expected.not_to include("branch-from-space") }

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :list_refs
  end

  describe '#tag_names' do
    subject { repository.tag_names }

    it { is_expected.to be_kind_of Array }

    it 'has some elements' do
      expect(subject.size).to be >= 1
    end

    it 'returns UTF-8' do
      expect(subject.first).to be_utf8
    end

    describe '#last' do
      subject { super().last }

      it { is_expected.to eq("v1.1.1") }
    end

    it { is_expected.to include("v1.0.0") }
    it { is_expected.not_to include("v5.0.0") }

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :list_refs
  end

  describe '#tags' do
    subject { repository.tags }

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :tags
  end

  describe '#archive_metadata' do
    let(:storage_path) { '/tmp' }
    let(:cache_key) { File.join(repository.gl_repository, TestEnv::BRANCH_SHA['master']) }

    let(:append_sha) { true }
    let(:ref) { 'master' }
    let(:format) { nil }
    let(:path) { nil }

    let(:expected_extension) { 'tar.gz' }
    let(:expected_filename) { "#{expected_prefix}.#{expected_extension}" }
    let(:expected_path) { File.join(storage_path, cache_key, "@v2", expected_filename) }
    let(:expected_prefix) { "gitlab-git-test-#{ref.tr('/', '-')}-#{expected_prefix_sha}" }
    let(:expected_prefix_sha) { TestEnv::BRANCH_SHA['master'] }

    subject(:metadata) { repository.archive_metadata(ref, storage_path, 'gitlab-git-test', format, append_sha: append_sha, path: path) }

    it 'sets CommitId to the commit SHA' do
      expect(metadata['CommitId']).to start_with(TestEnv::BRANCH_SHA['master'])
    end

    it 'sets ArchivePrefix to the expected prefix' do
      expect(metadata['ArchivePrefix']).to eq(expected_prefix)
    end

    it 'sets ArchivePath to the expected globally-unique path' do
      expect(expected_path).to include(File.join(repository.gl_repository, TestEnv::BRANCH_SHA['master']))

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
        sha = TestEnv::BRANCH_SHA['master']

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

    context 'when references are ambiguous' do
      let_it_be(:ambiguous_project) { create(:project, :repository) }
      let_it_be(:repository) { ambiguous_project.repository.raw }
      let_it_be(:branch_merged_commit_id) { ambiguous_project.repository.find_branch('branch-merged').dereferenced_target.id }
      let_it_be(:branch_master_commit_id) { ambiguous_project.repository.find_branch('master').dereferenced_target.id }
      let_it_be(:tag_1_0_0_commit_id) { ambiguous_project.repository.find_tag('v1.0.0').dereferenced_target.id }

      context 'when tag is ambiguous' do
        before do
          ambiguous_project.repository.add_tag(user, ref, 'master', 'foo')
        end

        after do
          ambiguous_project.repository.rm_tag(user, ref)
        end

        where(:ref, :expected_commit_id, :desc) do
          'refs/heads/branch-merged'    | ref(:branch_master_commit_id) | 'when tag looks like a branch'
          'branch-merged'               | ref(:branch_master_commit_id) | 'when tag has the same name as a branch'
          ref(:branch_merged_commit_id) | ref(:branch_merged_commit_id) | 'when tag looks like a commit id'
          'v0.0.0'                      | ref(:branch_master_commit_id) | 'when tag looks like a normal tag'
        end

        with_them do
          it 'selects the correct commit' do
            expect(metadata['CommitId']).to eq(expected_commit_id)
          end
        end
      end

      context 'when branch is ambiguous' do
        before do
          ambiguous_project.repository.add_branch(user, ref, 'master')
        end

        where(:ref, :expected_commit_id, :desc) do
          'refs/tags/v1.0.0'            | ref(:branch_master_commit_id) | 'when branch looks like a tag'
          'v1.0.0'                      | ref(:tag_1_0_0_commit_id)     | 'when branch has the same name as a tag'
          ref(:branch_merged_commit_id) | ref(:branch_merged_commit_id) | 'when branch looks like a commit id'
          'just-a-normal-branch'        | ref(:branch_master_commit_id) | 'when branch looks like a normal branch'
        end

        with_them do
          it 'selects the correct commit' do
            expect(metadata['CommitId']).to eq(expected_commit_id)
          end
        end
      end

      context 'when ref is HEAD' do
        let(:ref) { 'HEAD' }

        it 'selects commit id from HEAD ref' do
          expect(metadata['CommitId']).to eq(branch_master_commit_id)
          expect(metadata['ArchivePrefix']).to eq(expected_prefix)
        end
      end

      context 'when ref is not found' do
        let(:ref) { 'unknown-ref-cannot-be-found' }

        it 'returns empty metadata' do
          expect(metadata).to eq({})
        end
      end
    end
  end

  describe '#size' do
    subject { repository.size }

    it { is_expected.to be > 0 }
    it { is_expected.to be_a(Float) }

    it "uses repository_info for size" do
      expect(repository.gitaly_repository_client).to receive(:repository_info).and_call_original

      subject
    end

    context "when use_repository_info_for_repository_size feature flag is disabled" do
      before do
        stub_feature_flags(use_repository_info_for_repository_size: false)
      end

      it { is_expected.to be > 0 }
      it { is_expected.to be_a(Float) }

      it "uses repository_size for size" do
        expect(repository.gitaly_repository_client).to receive(:repository_size).and_call_original

        subject
      end
    end
  end

  describe '#recent_objects_size' do
    subject(:recent_objects_size) { repository.recent_objects_size }

    it { is_expected.to be_a(Float) }

    it 'uses repository_info for size' do
      expect(repository.gitaly_repository_client).to receive(:repository_info).and_call_original

      recent_objects_size
    end

    it 'returns the recent objects size' do
      objects_response = Gitaly::RepositoryInfoResponse::ObjectsInfo.new(recent_size: 5.megabytes)

      allow(repository.gitaly_repository_client).to receive(:repository_info).and_return(
        Gitaly::RepositoryInfoResponse.new(objects: objects_response)
      )

      expect(recent_objects_size).to eq 5.0
    end

    it_behaves_like 'wrapping gRPC errors', Gitaly::RepositoryInfoResponse::ObjectsInfo, :recent_size do
      subject { recent_objects_size }
    end
  end

  describe '#to_s' do
    subject { repository.to_s }

    it { is_expected.to eq("<Gitlab::Git::Repository: #{project.full_path}>") }
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

      it { is_expected.to eq(TestEnv::BRANCH_SHA.keys.min) }
    end

    describe '#last' do
      subject { super().last }

      it { is_expected.to eq('v1.1.1') }
    end
  end

  describe '#submodule_url_for' do
    let(:ref) { 'submodule_inside_folder' }

    def submodule_url(path)
      repository.submodule_url_for(ref, path)
    end

    it { expect(submodule_url('six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('test_inside_folder/another_folder/six')).to eq('git://github.com/randx/six.git') }
    it { expect(submodule_url('invalid/path')).to eq(nil) }

    context 'uncommitted submodule dir' do
      let(:ref) { 'fix-existing-submodule-dir' }

      it { expect(submodule_url('submodule-existing-dir')).to eq(nil) }
    end

    context 'tags' do
      let(:ref) { 'v1.1.1' }

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
        "gitlab-grack" => "https://gitlab.com/gitlab-org/gitlab-grack.git",
        "gitlab-shell" => "https://github.com/gitlabhq/gitlab-shell.git",
        "six" => "git://github.com/randx/six.git"
      })
    end
  end

  describe '#commit_count' do
    it { expect(repository.commit_count("master")).to eq(37) }
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

          left.times do |i|
            repository.commit_files(
              user,
              branch_name: 'left-branch',
              message: 'some more content for a',
              actions: [{
                action: i == 0 ? :create : :update,
                file_path: 'encoding/CHANGELOG',
                content: 'some stuff'
              }]
            )
          end

          right.times do |i|
            repository.commit_files(
              user,
              branch_name: 'right-branch',
              message: 'some more content for b',
              actions: [{
                action: i == 0 ? :create : :update,
                file_path: 'encoding/CHANGELOG',
                content: 'some stuff'
              }]
            )
          end
        end

        after do
          repository.delete_branch('left-branch')
          repository.delete_branch('right-branch')
        end

        it 'returns the correct count bounding at max_count' do
          branch_a_sha = repository.find_branch('left-branch').dereferenced_target.sha
          branch_b_sha = repository.find_branch('right-branch').dereferenced_target.sha

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

          left.times do |i|
            repository.commit_files(
              user,
              branch_name: 'left-branch',
              message: 'some more content for a',
              actions: [{
                action: i == 0 ? :create : :update,
                file_path: 'encoding/CHANGELOG',
                content: 'some stuff'
              }]
            )
          end

          right.times do |i|
            repository.commit_files(
              user,
              branch_name: 'right-branch',
              message: 'some more content for b',
              actions: [{
                action: i == 0 ? :create : :update,
                file_path: 'encoding/CHANGELOG',
                content: 'some stuff'
              }]
            )
          end
        end

        after do
          repository.delete_branch('left-branch')
          repository.delete_branch('right-branch')
        end

        it 'returns the correct count bounding at max_count' do
          branch_a_sha = repository.find_branch('left-branch').dereferenced_target.sha
          branch_b_sha = repository.find_branch('right-branch').dereferenced_target.sha

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
    end
  end

  describe '#delete_branch' do
    let(:repository) { mutable_repository }

    it 'deletes a branch' do
      expect(repository.find_branch('feature')).not_to be_nil

      repository.delete_branch('feature')

      expect(repository.find_branch('feature')).to be_nil
    end

    it 'deletes a fully qualified branch' do
      expect(repository.find_branch('feature')).not_to be_nil

      repository.delete_branch('refs/heads/feature')

      expect(repository.find_branch('feature')).to be_nil
    end
  end

  describe '#update_refs' do
    let(:repository) { mutable_repository }
    let(:sha) { TestEnv::BRANCH_SHA['master'] }
    let(:tmp_ref) { "refs/tmp/#{SecureRandom.hex}" }

    before do
      repository.write_ref(tmp_ref, sha)
    end

    it 'updates the ref' do
      expect do
        repository.update_refs(
          [
            {
              old_sha: sha,
              new_sha: Gitlab::Git::SHA1_BLANK_SHA,
              reference: tmp_ref
            }
          ]
        )
      end.to change { repository.ref_exists?(tmp_ref) }
        .from(true).to(false)
    end

    it 'does not call gitaly when no refs given' do
      expect_any_instance_of(Gitlab::GitalyClient::RefService).not_to receive(:update_refs)

      repository.update_refs([])
    end
  end

  describe '#delete_refs' do
    let(:repository) { mutable_repository }

    it 'deletes the ref' do
      repository.delete_refs('refs/heads/feature')

      expect(repository.find_branch('feature')).to be_nil
    end

    it 'deletes all refs' do
      refs = %w[refs/heads/wip refs/tags/v1.1.0]
      repository.delete_refs(*refs)

      expect(repository.list_refs(refs)).to be_empty
    end

    it 'does not fail when deleting an empty list of refs' do
      expect { repository.delete_refs(*[]) }.not_to raise_error
    end

    it 'raises an error if it failed' do
      expect { repository.delete_refs('refs\heads\fix') }.to raise_error(Gitlab::Git::InvalidRefFormatError)
    end
  end

  describe '#branch_names_contains_sha' do
    let(:head_id) { repository.commit.id }
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

    context 'when limit is provided' do
      it 'displays limited number of branches' do
        expect(repository.branch_names_contains_sha(head_id, limit: 1)).to match_array(['2-mb-file'])
      end
    end
  end

  describe "#refs_hash" do
    subject { repository.refs_hash }

    it "has as many entries as branches and tags" do
      # We flatten in case a commit is pointed at by more than one branch and/or tag
      expect(subject.values.flatten.size).to be > 0
    end

    it 'has valid commit ids as keys' do
      expect(subject.keys).to all(match(Commit::COMMIT_SHA_PATTERN))
    end

    it 'does not error when dereferenced_target is nil' do
      blob_id = repository.blob_at('master', 'README.md').id
      repository.add_tag("refs/tags/blob-tag", user: user, target: blob_id)

      expect { subject }.not_to raise_error
    end
  end

  describe '#fetch_remote' do
    let(:url) { 'http://example.clom' }

    it 'delegates to the gitaly RepositoryService' do
      ssh_auth = double(:ssh_auth)
      expected_opts = {
        ssh_auth: ssh_auth,
        forced: true,
        no_tags: true,
        timeout: described_class::GITLAB_PROJECTS_TIMEOUT,
        prune: false,
        check_tags_changed: false,
        refmap: nil,
        http_authorization_header: "",
        resolved_address: '172.16.123.1'
      }

      expect(repository.gitaly_repository_client).to receive(:fetch_remote).with(url, expected_opts)

      repository.fetch_remote(url, ssh_auth: ssh_auth, forced: true, no_tags: true, prune: false, check_tags_changed: false, resolved_address: '172.16.123.1')
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :fetch_remote do
      subject { repository.fetch_remote(url) }
    end
  end

  describe '#search_files_by_content' do
    let(:repository) { mutable_repository }
    let(:ref) { 'search-files-by-content-branch' }
    let(:content) { 'foobarbazmepmep' }

    before do
      repository.create_branch(ref)
      repository.commit_files(
        user,
        branch_name: ref,
        message: 'committing something',
        actions: [{
          action: :create,
          file_path: 'encoding/CHANGELOG',
          content: content
        }]
      )
      repository.commit_files(
        user,
        branch_name: ref,
        message: 'committing something',
        actions: [{
          action: :create,
          file_path: 'anotherfile',
          content: content
        }]
      )
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
        expect(result).to contain_exactly('files/ruby/popen.rb',
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

  describe '#search_files_by_name' do
    let(:ref) { 'master' }

    subject(:result) { mutable_repository.search_files_by_name(query, ref) }

    context 'when sending a valid name' do
      let(:query) { 'files/ruby/popen.rb' }

      it 'returns matched files' do
        expect(result).to contain_exactly('files/ruby/popen.rb')
      end
    end

    context 'when sending a name with space' do
      let(:query) { 'file with space.md' }

      before do
        mutable_repository.commit_files(
          user,
          actions: [{ action: :create, file_path: "file with space.md", content: "Test content" }],
          branch_name: ref, message: "Test"
        )
      end

      it 'returns matched files' do
        expect(result).to contain_exactly('file with space.md')
      end
    end

    context 'when sending a name with special ASCII characters' do
      let(:file_name) { 'Hello !@#$%^&*()' }
      let(:query) { file_name }

      before do
        mutable_repository.commit_files(
          user,
          actions: [{ action: :create, file_path: file_name, content: "Test content" }],
          branch_name: ref, message: "Test"
        )
      end

      it 'returns matched files' do
        expect(result).to contain_exactly(file_name)
      end
    end

    context 'when sending a non-existing name' do
      let(:query) { 'please do not exist.md' }

      it 'raises error' do
        expect(result).to eql([])
      end
    end
  end

  describe '#find_remote_root_ref' do
    it 'gets the remote root ref from GitalyClient' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .to receive(:find_remote_root_ref).and_call_original

      expect(repository.find_remote_root_ref(TestEnv.factory_repo_path.to_s)).to eq 'master'
    end

    it 'returns UTF-8' do
      expect(repository.find_remote_root_ref(TestEnv.factory_repo_path.to_s)).to be_utf8
    end

    it 'returns nil when remote name is nil' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .not_to receive(:find_remote_root_ref)

      expect(repository.find_remote_root_ref(nil)).to be_nil
    end

    it 'returns nil when remote name is empty' do
      expect_any_instance_of(Gitlab::GitalyClient::RemoteService)
        .not_to receive(:find_remote_root_ref)

      expect(repository.find_remote_root_ref('')).to be_nil
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RemoteService, :find_remote_root_ref do
      subject { repository.find_remote_root_ref(TestEnv.factory_repo_path.to_s) }
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
        @commit_with_old_name_id = repository.commit_files(
          user,
          branch_name: repository.root_ref,
          message: 'Update CHANGELOG',
          actions: [{
            action: :update,
            file_path: 'CHANGELOG',
            content: 'CHANGELOG'
          }]
        ).newrev
        @rename_commit_id = repository.commit_files(
          user,
          branch_name: repository.root_ref,
          message: 'Move CHANGELOG to encoding/',
          actions: [{
            action: :move,
            previous_path: 'CHANGELOG',
            file_path: 'encoding/CHANGELOG',
            content: 'CHANGELOG'
          }]
        ).newrev
        @commit_with_new_name_id = repository.commit_files(
          user,
          branch_name: repository.root_ref,
          message: 'Edit encoding/CHANGELOG',
          actions: [{
            action: :update,
            file_path: 'encoding/CHANGELOG',
            content: "I'm a new changelog with different text"
          }]
        ).newrev
      end

      after do
        # Erase our commits so other tests get the original repo
        repository.write_ref(repository.root_ref, TestEnv::BRANCH_SHA['master'])
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
          commit.deltas.flat_map do |delta|
            [delta.old_path, delta.new_path].uniq.compact
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

          expect(commits.size).to eq(50)
        end
      end
    end

    context 'when Gitaly find_commits feature is enabled' do
      it_behaves_like 'repository log'
    end
  end

  describe '#blobs' do
    let_it_be(:commit_oid) { TestEnv::BRANCH_SHA['master'] }

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
      let(:expected_blobs) { 52 }

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
      let(:revisions) { [::Gitlab::Git::SHA1_BLANK_SHA] }
      let(:expected_blobs) { 0 }

      before do
        expect_any_instance_of(Gitlab::GitalyClient::BlobService)
          .not_to receive(:list_blobs)
      end

      it_behaves_like 'a blob enumeration'
    end
  end

  describe '#new_blobs' do
    let(:repository) { mutable_repository }
    let(:commit) { create_commit('nested/new-blob.txt' => 'This is a new blob') }

    def create_commit(blobs)
      commit_result = repository.commit_files(
        user,
        branch_name: 'a-new-branch',
        message: 'Add a file',
        actions: blobs.map do |path, content|
          {
            action: :create,
            file_path: path,
            content: content
          }
        end
      )

      # new_blobs only returns unreferenced blobs because it is used for hooks.
      # Gitaly does not allow us to create loose objects via the RPC.
      repository.delete_branch('a-new-branch')

      commit_result.newrev
    end

    subject { repository.new_blobs(newrevs) }

    describe 'memoization' do
      before do
        allow(repository).to receive(:blobs).once.with(["--not", "--all", "--not", "revision1"], kind_of(Hash))
          .and_return(['first result'])
        repository.new_blobs(['revision1'])
      end

      it 'calls blobs only once' do
        expect(repository.new_blobs(['revision1'])).to eq(['first result'])
      end

      context 'when called with a different revision' do
        before do
          allow(repository).to receive(:blobs).once.with(["--not", "--all", "--not", "revision2"], kind_of(Hash))
            .and_return(['second result'])
          repository.new_blobs(['revision2'])
        end

        it 'memoizes the different arguments' do
          expect(repository.new_blobs(['revision2'])).to eq(['second result'])
        end
      end
    end

    shared_examples '#new_blobs with revisions' do
      before do
        expect_next_instance_of(Gitlab::GitalyClient::BlobService) do |service|
          expect(service)
            .to receive(:list_blobs)
            .with(expected_newrevs,
              limit: Gitlab::Git::Repository::REV_LIST_COMMIT_LIMIT,
              with_paths: true,
              dynamic_timeout: nil)
            .once
            .and_call_original
        end
      end

      it 'enumerates new blobs' do
        expect(subject).to match_array(expected_blobs)
      end

      it 'memoizes results' do
        expect(subject).to match_array(expected_blobs)

        # call subject again
        expect(repository.new_blobs(newrevs)).to match_array(expected_blobs)
      end
    end

    context 'with a single revision' do
      let(:newrevs) { commit }
      let(:expected_newrevs) { ['--not', '--all', '--not', newrevs] }
      let(:expected_blobs) do
        [have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'nested/new-blob.txt', size: 18)]
      end

      it_behaves_like '#new_blobs with revisions'
    end

    context 'with a single-entry array' do
      let(:newrevs) { [commit] }
      let(:expected_newrevs) { ['--not', '--all', '--not'] + newrevs }
      let(:expected_blobs) do
        [have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'nested/new-blob.txt', size: 18)]
      end

      it_behaves_like '#new_blobs with revisions'
    end

    context 'with multiple revisions' do
      let(:newrevs) { [commit, create_commit('another_path.txt' => 'Another blob')] }
      let(:expected_newrevs) { ['--not', '--all', '--not'] + newrevs.sort }
      let(:expected_blobs) do
        [
          have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'nested/new-blob.txt', size: 18),
          have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'another_path.txt', size: 12)
        ]
      end

      it_behaves_like '#new_blobs with revisions'
    end

    context 'with partially blank revisions' do
      let(:newrevs) { [nil, commit, Gitlab::Git::SHA1_BLANK_SHA] }
      let(:expected_newrevs) { ['--not', '--all', '--not', commit] }
      let(:expected_blobs) do
        [
          have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'nested/new-blob.txt', size: 18)
        ]
      end

      it_behaves_like '#new_blobs with revisions'
    end

    context 'with repeated revisions' do
      let(:newrevs) { [commit, commit, commit] }
      let(:expected_newrevs) { ['--not', '--all', '--not', commit] }
      let(:expected_blobs) do
        [
          have_attributes(class: Gitlab::Git::Blob, id: an_instance_of(String), path: 'nested/new-blob.txt', size: 18)
        ]
      end

      it_behaves_like '#new_blobs with revisions'
    end

    context 'with preexisting commits' do
      let(:newrevs) { ['refs/heads/master'] }
      let(:expected_newrevs) { ['--not', '--all', '--not'] + newrevs }
      let(:expected_blobs) { [] }

      it_behaves_like '#new_blobs with revisions'
    end

    shared_examples '#new_blobs without revisions' do
      before do
        expect(Gitlab::GitalyClient::BlobService).not_to receive(:new)
      end

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'with a single nil newrev' do
      let(:newrevs) { nil }

      it_behaves_like '#new_blobs without revisions'
    end

    context 'with a single zero newrev' do
      let(:newrevs) { Gitlab::Git::SHA1_BLANK_SHA }

      it_behaves_like '#new_blobs without revisions'
    end

    context 'with an empty array' do
      let(:newrevs) { [] }

      it_behaves_like '#new_blobs without revisions'
    end

    context 'with array containing only empty refs' do
      let(:newrevs) { [nil, Gitlab::Git::SHA1_BLANK_SHA] }

      it_behaves_like '#new_blobs without revisions'
    end
  end

  describe '#new_commits' do
    let(:repository) { mutable_repository }
    let(:new_commit) do
      commit_result = repository.commit_files(
        user,
        branch_name: 'a-new-branch',
        message: 'Message',
        actions: [{
          action: :create,
          file_path: 'some_file.txt',
          content: 'This is a file'
        }]
      )

      # new_commits only returns unreferenced commits because it is used for
      # hooks. Gitaly does not allow us to create loose objects via the RPC.
      repository.delete_branch('a-new-branch')

      commit_result.newrev
    end

    let(:expected_commits) { 1 }
    let(:revisions) { [new_commit] }

    before do
      expect_next_instance_of(Gitlab::GitalyClient::CommitService) do |service|
        expect(service)
          .to receive(:list_commits)
          .with([new_commit, '--not', '--all'])
          .and_call_original
      end
    end

    it 'enumerates commits' do
      commits = repository.new_commits(revisions).to_a

      expect(commits.size).to eq(expected_commits)
      commits.each do |commit|
        expect(commit.id).to eq(new_commit)
        expect(commit.message).to eq("Message")
      end
    end
  end

  describe '#count_commits_between' do
    subject { repository.count_commits_between('feature', 'master') }

    it { is_expected.to eq(29) }
  end

  describe '#raw_changes_between' do
    let(:old_rev) {}
    let(:new_rev) {}
    let(:changes) { repository.raw_changes_between(old_rev, new_rev) }

    context 'initial commit' do
      let(:old_rev) { Gitlab::Git::SHA1_BLANK_SHA }
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

    context 'with valid revs', :aggregate_failures do
      let(:old_rev) { TestEnv::BRANCH_SHA['feature'] }
      let(:new_rev) { TestEnv::BRANCH_SHA['master'] }

      it 'returns the changes' do
        expect(changes.size).to eq(21)
        expect(changes.first.operation).to eq(:deleted)
        expect(changes.first.old_path).to eq('.DS_Store')
        expect(changes.last.operation).to eq(:added)
        expect(changes.last.new_path).to eq('with space/README.md')
      end
    end
  end

  describe '#merge_base' do
    where(:from, :to, :result) do
      'master'  | 'feature' | 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f'
      'feature' | 'master'  | 'ae73cb07c9eeaf35924a10f713b364d32b2dd34f'
      'master'  | 'foobar'  | nil
      'foobar'  | 'master'  | nil
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

          expect(repository.count_commits(options)).to eq(37)
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
        it 'returns the number of commits ahead for master..feature' do
          options = { from: 'master', to: 'feature' }

          expect(repository.count_commits(options)).to eq(1)
        end

        it 'returns the number of commits ahead for feature..master' do
          options = { from: 'feature', to: 'master' }

          expect(repository.count_commits(options)).to eq(29)
        end

        context 'with option :left_right' do
          it 'returns the number of commits for master..feature' do
            options = { from: 'master', to: 'feature', left_right: true }

            expect(repository.count_commits(options)).to eq([29, 1])
          end

          context 'with max_count' do
            it 'returns the number of commits' do
              options = { from: 'feature', to: 'master', left_right: true, max_count: 1 }

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

          expect(repository.count_commits(options)).to eq(328)
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

    context 'when branch is ambiguous' do
      let(:ambiguous_branch) { 'prefix' }
      let(:branch_with_prefix) { 'prefix/branch' }

      before do
        repository.create_branch(branch_with_prefix)
      end

      after do
        repository.delete_branch(branch_with_prefix)
      end

      it 'returns nil for ambiguous branch' do
        expect(repository.find_branch(branch_with_prefix)).to be_a_kind_of(Gitlab::Git::Branch)
        expect(repository.find_branch(ambiguous_branch)).to eq(nil)
      end
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

      it 'returns the local and remote branches' do
        expect(subject.any? { |b| b.name == 'joe/remote_branch' }).to eq(true)
        expect(subject.any? { |b| b.name == 'local_branch' }).to eq(true)
      end
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RefService, :branches
  end

  describe '#branch_count' do
    it 'returns the number of branches' do
      expect(repository.branch_count).to eq(TestEnv::BRANCH_SHA.size)
    end

    context 'with local and remote branches' do
      let(:repository) { mutable_repository }

      before do
        create_remote_branch('joe', 'remote_branch', 'master')
        repository.create_branch('local_branch')
      end

      it 'returns the count of local branches' do
        expect(repository.branch_count).to eq(repository.local_branches.count)
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
      let(:repository) { mutable_repository }

      before do
        repository.create_branch('identical')
      end

      it 'returns all merged branch names except for identical one' do
        names = repository.merged_branch_names

        expect(names).to match_array(["'test'", "branch-merged", "flatten-dir", "improve/awesome", "merge-test"])
      end
    end
  end

  describe '#diff_blobs' do
    let(:gitaly_diff_client) { double('Gitlab::GitalyClient::DiffService') }

    # SHAs used are from https://gitlab.com/gitlab-org/gitlab-test.
    let(:left_blob) { '1e292f8fedd741b75372e19097c76d327140c312' }
    let(:right_blob) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }

    let(:blob_pairs) do
      [
        Gitaly::DiffBlobsRequest::BlobPair.new(
          left_blob: left_blob,
          right_blob: right_blob
        )
      ]
    end

    before do
      allow(repository).to receive(:gitaly_diff_client).and_return(gitaly_diff_client)
      allow(gitaly_diff_client).to receive(:diff_blobs)

      repository.diff_blobs(blob_pairs)
    end

    it 'passes the values to the diff client' do
      expect(gitaly_diff_client)
        .to have_received(:diff_blobs)
        .with(blob_pairs)
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

    it 'returns no Gitaly::DiffStats when there is a SHA1_BLANK_SHA' do
      expect_any_instance_of(Gitlab::GitalyClient::CommitService)
        .not_to receive(:diff_stats)

      collection = repository.diff_stats(Gitlab::Git::SHA1_BLANK_SHA, 'master')

      expect(collection).to be_a(Gitlab::Git::DiffStatsCollection)
      expect(collection).to be_a(Enumerable)
      expect(collection.to_a).to be_empty
    end
  end

  describe '#find_changed_paths' do
    let_it_be(:commit_1) { repository.commit(TestEnv::BRANCH_SHA['with-executables']) }
    let_it_be(:commit_2) { repository.commit(TestEnv::BRANCH_SHA['master']) }
    let_it_be(:commit_3) { repository.commit('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }

    let_it_be(:initial_commit) { repository.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863') }

    let(:commit_1_files) do
      [
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "files/executables/ls", old_path: '', old_mode: "0", new_mode: "100755",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: 'c84acd1ff0b844201312052f9bb3b7259eb2e177'
        )
      ]
    end

    let(:commit_2_files) do
      [
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "bar/branch-test.txt", old_path: '', old_mode: "0", new_mode: "100644",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '93e123ac8a3e6a0b600953d7598af629dec7b735'
        )
      ]
    end

    let(:commit_3_files) do
      [
        Gitlab::Git::ChangedPath.new(
          status: :MODIFIED, path: ".gitmodules", old_path: '', old_mode: "100644", new_mode: "100644",
          old_blob_id: 'fdaada1754989978413d618ee1fb1c0469d6a664', new_blob_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "gitlab-shell", old_path: '', old_mode: "0", new_mode: "160000",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '79bceae69cb5750d6567b223597999bfa91cb3b9'
        )
      ]
    end

    let(:initial_commit_files) do
      [
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: ".gitignore", old_path: '', old_mode: "0", new_mode: "100644",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '470ad2fcf1e33798f1afc5781d08e60c40f51e7a'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "LICENSE", old_path: '', old_mode: "0", new_mode: "100644",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '50b27c6518be44c42c4d87966ae2481ce895624c'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "README.md", old_path: '', old_mode: "0", new_mode: "100644",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: 'faaf198af3a36dbf41961466703cc1d47c61d051'
        )
      ]
    end

    it 'returns a list of paths' do
      collection = repository.find_changed_paths([commit_1, commit_2, commit_3, initial_commit])

      expect(collection).to be_a(Enumerable)
      expect(collection.as_json).to eq((commit_1_files + commit_2_files + commit_3_files + initial_commit_files).as_json)
    end

    it 'returns only paths with valid SHAs' do
      collection = repository.find_changed_paths(['invalid', commit_1])

      expect(collection).to be_a(Enumerable)
      expect(collection.as_json).to eq(commit_1_files.as_json)
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

    describe 'optional arguments' do
      let(:gitaly_commit_client) { double('Gitlab::GitalyClient::CommitService') }

      before do
        allow(repository).to receive(:gitaly_commit_client).and_return(gitaly_commit_client)
        allow(gitaly_commit_client).to receive(:find_changed_paths)
      end

      context 'when omitted' do
        before do
          repository.find_changed_paths(['sha'])
        end

        it 'returns default values' do
          expect(gitaly_commit_client)
            .to have_received(:find_changed_paths)
            .with(['sha'], merge_commit_diff_mode: nil, find_renames: false)
        end
      end

      context 'merge_commit_diff_mode is given' do
        let(:merge_commit_diff_mode) { 'foobar' }

        before do
          repository.find_changed_paths(['sha'], merge_commit_diff_mode: merge_commit_diff_mode)
        end

        it 'passes the value on to the commit client' do
          expect(gitaly_commit_client)
            .to have_received(:find_changed_paths)
            .with(['sha'], merge_commit_diff_mode: merge_commit_diff_mode, find_renames: false)
        end
      end

      context 'find_names is included' do
        let(:find_renames) { true }

        before do
          repository.find_changed_paths(['sha'], find_renames: find_renames)
        end

        it 'passes the value on to the commit client' do
          expect(gitaly_commit_client)
            .to have_received(:find_changed_paths)
            .with(['sha'], merge_commit_diff_mode: nil, find_renames: find_renames)
        end
      end
    end
  end

  describe "#ls_files" do
    let(:master_file_paths) { repository.ls_files("master") }
    let(:utf8_file_paths) { repository.ls_files("ls-files-utf8") }
    let(:not_existed_branch) { repository.ls_files("not_existed_branch") }

    it "read every file paths of master branch" do
      expect(master_file_paths.length).to equal(38)
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

  describe '#gitattribute' do
    let(:repository) { mutable_repository }

    context 'with gitattributes' do
      before do
        # This line is added to make sure this test works when gitaly stops using
        # info/attributes. See https://gitlab.com/gitlab-org/gitaly/-/issues/5348 for details.
        repository.write_ref('HEAD', 'refs/heads/gitattributes')
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
    end

    context 'without gitattributes' do
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

  describe '#find_tag' do
    it 'returns a tag' do
      tag = repository.find_tag('v1.0.0')

      expect(tag).to be_a_kind_of(Gitlab::Git::Tag)
      expect(tag.name).to eq('v1.0.0')
    end

    shared_examples 'a nonexistent tag' do
      it 'returns nil' do
        expect(repository.find_tag('this-is-garbage')).to be_nil
      end
    end

    context 'when asking for a non-existent tag' do
      it_behaves_like 'a nonexistent tag'
    end

    context 'when Gitaly returns Internal error' do
      before do
        expect(Gitlab::GitalyClient)
          .to receive(:call)
          .and_raise(GRPC::Internal, "tag not found")
      end

      it_behaves_like 'a nonexistent tag'
    end

    context 'when Gitaly returns tag_not_found error' do
      before do
        expect(Gitlab::GitalyClient)
          .to receive(:call)
          .and_raise(new_detailed_error(GRPC::Core::StatusCodes::NOT_FOUND,
            "tag was not found",
            Gitaly::FindTagError.new(tag_not_found: Gitaly::ReferenceNotFoundError.new)))
      end

      it_behaves_like 'a nonexistent tag'
    end
  end

  describe '#languages' do
    it 'returns exactly the expected results' do
      languages = repository.languages(TestEnv::BRANCH_SHA['master'])

      expect(languages).to match_array(
        [
          { value: a_value_within(0.1).of(66.7), label: "Ruby", color: "#701516", highlight: "#701516" },
          { value: a_value_within(0.1).of(22.96), label: "JavaScript", color: "#f1e05a", highlight: "#f1e05a" },
          { value: a_value_within(0.1).of(7.9), label: "HTML", color: "#e34c26", highlight: "#e34c26" },
          { value: a_value_within(0.1).of(2.51), label: "CoffeeScript", color: "#244776", highlight: "#244776" }
        ])
    end

    it "uses the repository's HEAD when no ref is passed" do
      lang = repository.languages.first

      expect(lang[:label]).to eq('Ruby')
    end
  end

  describe '#license' do
    subject(:license) { repository.license }

    context 'when no license file can be found' do
      let_it_be(:project) { create(:project, :repository) }
      let(:repository) { project.repository.raw_repository }

      before do
        project.repository.delete_file(project.owner, 'LICENSE', message: 'remove license', branch_name: 'master')
      end

      it { is_expected.to be_nil }
    end

    context 'when an mit license is found' do
      it { is_expected.to have_attributes(key: 'mit') }
    end

    context 'when license is not recognized ' do
      let_it_be(:project) { create(:project, :repository) }
      let(:repository) { project.repository.raw_repository }

      before do
        project.repository.update_file(
          project.owner,
          'LICENSE',
          'This software is licensed under the Dummy license.',
          message: 'Update license',
          branch_name: 'master')
      end

      it { is_expected.to have_attributes(key: 'other', nickname: 'LICENSE') }
    end
  end

  describe '#fetch_source_branch!' do
    let(:local_ref) { 'refs/merge-requests/1/head' }
    let(:repository) { create(:project, :repository).repository.raw }
    let(:source_repository) { mutable_repository }

    context 'when the branch exists' do
      context 'when the commit does not exist locally' do
        let(:source_branch) { 'new-branch-for-fetch-source-branch' }

        let!(:new_oid) do
          source_repository.commit_files(
            user,
            branch_name: source_branch,
            message: 'Add a file',
            actions: [{
              action: :create,
              file_path: 'a.file',
              content: 'This is a file.'
            }]
          ).newrev
        end

        it 'writes the ref' do
          expect(repository.fetch_source_branch!(source_repository, source_branch, local_ref)).to eq(true)
          expect(repository.commit(local_ref).sha).to eq(new_oid)
        end
      end

      context 'when the commit exists locally' do
        let(:source_branch) { 'master' }
        let(:expected_oid) { TestEnv::BRANCH_SHA['master'] }

        it 'writes the ref' do
          # Sanity check: the commit should already exist
          expect(repository.commit(expected_oid)).not_to be_nil

          expect(repository.fetch_source_branch!(source_repository, source_branch, local_ref)).to eq(true)
          expect(repository.commit(local_ref).sha).to start_with(expected_oid)
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
    let(:target_sha) { repository.commit(branch_name).sha }

    before do
      project.add_developer(user)
      repository.create_branch(branch_name)
    end

    it "removes the branch from the repo" do
      repository.rm_branch(branch_name, user: user, target_sha: target_sha)

      expect(repository.find_branch(branch_name)).to be_nil
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
      repository.write_ref('refs/heads/feature', TestEnv::BRANCH_SHA['master'])

      expect(repository.commit('feature').sha).to start_with(TestEnv::BRANCH_SHA['master'])
    end
  end

  describe '#list_refs' do
    it 'returns a list of branches with their head commit' do
      refs = repository.list_refs
      reference = refs.first

      expect(refs).to be_an(Enumerable)
      expect(reference).to be_a(Gitaly::ListRefsResponse::Reference)
      expect(reference.name).to be_a(String)
      expect(reference.target).to be_a(String)
    end

    it 'filters by pattern' do
      refs = repository.list_refs([Gitlab::Git::TAG_REF_PREFIX])

      refs.each do |reference|
        expect(reference.name).to include(Gitlab::Git::TAG_REF_PREFIX)
      end
    end

    context 'with pointing_at_oids and peel_tags options' do
      let(:commit_id) { mutable_repository.commit.id }
      let!(:annotated_tag) { mutable_repository.add_tag('annotated-tag', user: user, target: commit_id, message: 'Tag message') }
      let!(:lw_tag) { mutable_repository.add_tag('lw-tag', user: user, target: commit_id) }

      it 'filters by target OIDs' do
        refs = mutable_repository.list_refs([Gitlab::Git::TAG_REF_PREFIX], pointing_at_oids: [commit_id])

        expect(refs.length).to eq(2)
        expect(refs).to contain_exactly(
          Gitaly::ListRefsResponse::Reference.new(
            name: "#{Gitlab::Git::TAG_REF_PREFIX}#{lw_tag.name}",
            target: commit_id
          ),
          Gitaly::ListRefsResponse::Reference.new(
            name: "#{Gitlab::Git::TAG_REF_PREFIX}#{annotated_tag.name}",
            target: annotated_tag.id
          )
        )
      end

      it 'returns peeled_target for annotated tags' do
        refs = mutable_repository.list_refs([Gitlab::Git::TAG_REF_PREFIX], pointing_at_oids: [commit_id], peel_tags: true)

        expect(refs.length).to eq(2)
        expect(refs).to contain_exactly(
          Gitaly::ListRefsResponse::Reference.new(
            name: "#{Gitlab::Git::TAG_REF_PREFIX}#{lw_tag.name}",
            target: commit_id
          ),
          Gitaly::ListRefsResponse::Reference.new(
            name: "#{Gitlab::Git::TAG_REF_PREFIX}#{annotated_tag.name}",
            target: annotated_tag.id,
            peeled_target: commit_id
          )
        )
      end
    end
  end

  describe '#refs_by_oid' do
    it 'returns a list of refs from a OID' do
      refs = repository.refs_by_oid(oid: repository.commit.id)

      expect(refs).to be_an(Array)
      expect(refs).to include(Gitlab::Git::BRANCH_REF_PREFIX + repository.root_ref)
    end

    it 'returns a single ref from a OID' do
      refs = repository.refs_by_oid(oid: repository.commit.id, limit: 1)

      expect(refs).to be_an(Array)
      expect(refs).to eq([Gitlab::Git::BRANCH_REF_PREFIX + repository.root_ref])
    end

    it 'returns empty for unknown ID' do
      expect(repository.refs_by_oid(oid: Gitlab::Git::SHA1_BLANK_SHA, limit: 0)).to eq([])
    end

    it 'returns empty for an empty repo' do
      project = create(:project)

      expect(project.repository.refs_by_oid(oid: TestEnv::BRANCH_SHA['master'], limit: 0)).to eq([])
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
    let(:target_sha) { '6d394385cf567f80a8fd85055db1ab4c5295806f' }

    before do
      repository.create_branch(target_branch, target_sha)
    end

    it 'can perform a merge' do
      merge_commit_id = nil
      result =
        repository.merge(user,
          source_sha: source_sha,
          target_branch: target_branch,
          target_sha: target_sha,
          message: 'Test merge') do |commit_id|
            merge_commit_id = commit_id
          end

      expect(result.newrev).to eq(merge_commit_id)
      expect(result.repo_created).to eq(false)
      expect(result.branch_created).to eq(false)
    end

    it 'returns nil if there was a concurrent branch update' do
      concurrent_update_id = '33f3729a45c02fc67d00adb1b8bca394b0e761d9'
      result =
        repository.merge(user,
          source_sha: source_sha,
          target_branch: target_branch,
          target_sha: target_sha,
          message: 'Test merge') do |_commit_id|
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

    subject do
      repository.ff_merge(user,
        source_sha: source_sha,
        target_branch: target_branch,
        target_sha: branch_head
      )
    end

    shared_examples '#ff_merge' do
      it 'performs a ff_merge' do
        expect(subject.newrev).to eq(source_sha)
        expect(subject.repo_created).to be(false)
        expect(subject.branch_created).to be(false)

        expect(repository.commit(target_branch).id).to eq(source_sha)
      end

      context 'with a non-existing target branch' do
        subject { repository.ff_merge(user, source_sha: source_sha, target_branch: 'this-isnt-real') }

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
        .to receive(:user_ff_branch).with(
          user, source_sha: source_sha, target_branch: target_branch, target_sha: branch_head
        ).and_return(nil)

      subject
    end

    it_behaves_like '#ff_merge'
  end

  describe '#delete_all_refs_except' do
    let(:repository) { mutable_repository }

    before do
      repository.write_ref("refs/delete/a", TestEnv::BRANCH_SHA['master'])
      repository.write_ref("refs/also-delete/b", TestEnv::BRANCH_SHA['master'])
      repository.write_ref("refs/keep/c", TestEnv::BRANCH_SHA['master'])
      repository.write_ref("refs/also-keep/d", TestEnv::BRANCH_SHA['master'])
    end

    it 'deletes all refs except those with the specified prefixes' do
      repository.delete_all_refs_except(%w[refs/keep refs/also-keep refs/heads])
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

      expect(File).to exist(save_path)
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
    it 'compares two branches cross repo' do
      mutable_repository.commit_files(
        user,
        branch_name: mutable_repository.root_ref, message: 'Committing something',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'New file' }]
      )

      repository.commit_files(
        user,
        branch_name: repository.root_ref, message: 'Commit to root ref',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'One more' }]
      )

      [
        [repository, mutable_repository, true],
        [repository, mutable_repository, false],
        [mutable_repository, repository, true],
        [mutable_repository, repository, false]
      ].each do |source_repo, target_repo, straight|
        raw_compare = target_repo.compare_source_branch(
          target_repo.root_ref, source_repo, source_repo.root_ref, straight: straight)

        expect(raw_compare).to be_a(::Gitlab::Git::Compare)

        expect(raw_compare.commits).to eq([source_repo.commit])
        expect(raw_compare.head).to eq(source_repo.commit)
        expect(raw_compare.base).to eq(target_repo.commit)
        expect(raw_compare.straight).to eq(straight)
      end
    end

    context 'source ref does not exist in source repo' do
      it 'returns an empty comparison' do
        expect_next_instance_of(::Gitlab::Git::CrossRepo) do |instance|
          expect(instance).not_to receive(:fetch_source_branch!)
        end

        raw_compare = repository.compare_source_branch(
          repository.root_ref, mutable_repository, 'does-not-exist', straight: true)

        expect(raw_compare).to be_a(::Gitlab::Git::Compare)
        expect(raw_compare.commits.size).to eq(0)
      end
    end
  end

  describe '#checksum' do
    it 'calculates the checksum for non-empty repo' do
      expect(repository.checksum.length).to be(40)
      expect(Gitlab::Git.blank_ref?(repository.checksum)).to be false
    end

    it 'returns a blank sha for an empty repo' do
      repository = create(:project, :empty_repo).repository

      expect(Gitlab::Git.blank_ref?(repository.checksum)).to be true
    end

    it 'raises NoRepository for a non-existent repo' do
      repository = create(:project).repository

      expect do
        repository.checksum
      end.to raise_error(described_class::NoRepository)
    end
  end

  describe '#replicas', :praefect do
    it 'gets the replica checksum through praefect' do
      resp = repository.replicas

      expect(resp.replicas).to be_empty
      expect(resp.primary.checksum).to eq(repository.checksum)
    end
  end

  describe '#get_patch_id' do
    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::CommitService, :get_patch_id do
      subject { repository.get_patch_id('HEAD~', 'HEAD') }
    end
  end

  def create_remote_branch(remote_name, branch_name, source_branch_name)
    source_branch = repository.find_branch(source_branch_name)
    repository.write_ref("refs/remotes/#{remote_name}/#{branch_name}", source_branch.dereferenced_target.sha)
  end

  describe '#disconnect_alternates' do
    let(:project) { mutable_project }
    let(:repository) { mutable_repository }
    let(:pool_repository) { create(:pool_repository, :ready, source_project: project) }
    let(:object_pool) { pool_repository.object_pool }

    it 'does not raise an error when disconnecting a non-linked repository' do
      expect { repository.disconnect_alternates }.not_to raise_error
    end

    it 'can still access objects in the object pool' do
      # Create a commit into a separate repository and fetch it into the object pool.
      # Writing directly to an object pool fails as we don't support them in the
      # authorization checks. Gitaly's pre-receive hook fails as a gl_repository is
      # not set object pools.
      #
      # Write the commit into a fork of the project. Gitaly places the fork into the same partition
      # with the main project and the object pool which enables fetching it later.
      forked_project = create(:project, :fork_repository, forked_from_project: project)
      new_commit_id = forked_project.repository.commit_files(
        forked_project.owner,
        branch_name: object_pool.repository.root_ref,
        message: 'Add a file',
        actions: [{
          action: :create,
          file_path: 'a.file',
          content: 'This is a file.'
        }]
      )

      # Fetch the new object into the object pool
      Gitlab::GitalyClient::ObjectPoolService.new(object_pool).fetch(forked_project.repository)

      object_pool.link(repository)

      expect(repository.commit(new_commit_id).id).to eq(new_commit_id)

      repository.disconnect_alternates

      expect(repository.commit(new_commit_id).id).to eq(new_commit_id)
    end
  end

  describe '#remove' do
    let(:repository) { mutable_repository }

    it 'removes the repository' do
      expect(repository.exists?).to be true

      repository.remove

      expect(repository.exists?).to be false
    end

    context 'when the repository does not exist' do
      let(:repository) { create(:project).repository }

      it 'is idempotent' do
        expect(repository.exists?).to be false

        repository.remove

        expect(repository.exists?).to be false
      end
    end
  end

  describe '#import_repository' do
    let_it_be(:repository) { create(:project).repository }

    let(:url) { 'http://invalid.invalid' }

    it 'raises an error if a relative path is provided' do
      expect { repository.import_repository('/foo') }.to raise_error(ArgumentError, /disk path/)
    end

    it 'raises an error if an absolute path is provided' do
      expect { repository.import_repository('./foo') }.to raise_error(ArgumentError, /disk path/)
    end

    it 'delegates to Gitaly' do
      expect_next_instance_of(Gitlab::GitalyClient::RepositoryService) do |svc|
        expect(svc).to receive(:import_repository).with(url, http_authorization_header: '', mirror: false, resolved_address: '').and_return(nil)
      end

      repository.import_repository(url)
    end

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :import_repository do
      subject { repository.import_repository('http://invalid.invalid') }
    end
  end

  describe '#replicate' do
    let(:new_repository) do
      Gitlab::Git::Repository.new('test_second_storage', repository.relative_path, '', 'group/project')
    end

    subject { new_repository.replicate(repository) }

    before do
      stub_storage_settings('test_second_storage' => {})
    end

    after do
      new_repository.remove
    end

    context 'destination does not exist' do
      it 'mirrors the source repository' do
        subject

        expect(new_repository.list_refs(['refs/'])).to eq(repository.list_refs(['refs/']))
      end
    end

    context 'destination exists' do
      before do
        new_repository.create_repository
      end

      it 'mirrors the source repository' do
        subject

        expect(new_repository.list_refs(['refs/'])).to eq(repository.list_refs(['refs/']))
      end

      context 'with keep-around refs' do
        let(:repository) { mutable_repository }
        let(:sha) { TestEnv::BRANCH_SHA['master'] }
        let(:keep_around_ref) { "refs/keep-around/#{sha}" }
        let(:tmp_ref) { "refs/tmp/#{SecureRandom.hex}" }

        before do
          repository.write_ref(keep_around_ref, sha)
          repository.write_ref(tmp_ref, sha)
        end

        it 'includes the temporary and keep-around refs' do
          subject

          expect(new_repository.list_refs([keep_around_ref]).map(&:name)).to match_array([keep_around_ref])
          expect(new_repository.list_refs([tmp_ref]).map(&:name)).to match_array([tmp_ref])
        end
      end
    end
  end

  describe '#check_objects_exist' do
    it 'returns hash specifying which object exists in repo' do
      refs_exist = %w[
        b83d6e391c22777fca1ed3012fce84f633d7fed0
        498214de67004b1da3d820901307bed2a68a8ef6
        1b12f15a11fc6e62177bef08f47bc7b5ce50b141
      ]
      refs_dont_exist = %w[
        1111111111111111111111111111111111111111
        2222222222222222222222222222222222222222
      ]
      object_existence_map = repository.check_objects_exist(refs_exist + refs_dont_exist)
      expect(object_existence_map).to eq({
        'b83d6e391c22777fca1ed3012fce84f633d7fed0' => true,
        '498214de67004b1da3d820901307bed2a68a8ef6' => true,
        '1b12f15a11fc6e62177bef08f47bc7b5ce50b141' => true,
        '1111111111111111111111111111111111111111' => false,
        '2222222222222222222222222222222222222222' => false
      })
      expect(object_existence_map.keys).to eq(refs_exist + refs_dont_exist)

      single_sha = 'b83d6e391c22777fca1ed3012fce84f633d7fed0'
      expect(repository.check_objects_exist(single_sha)).to eq({ single_sha => true })
    end
  end

  describe '#list_all_blobs' do
    subject { repository.list_all_blobs(expected_params) }

    let(:expected_params) { { bytes_limit: 0, dynamic_timeout: nil, ignore_alternate_object_directories: true } }

    it 'calls delegates to BlobService' do
      expect(repository.gitaly_blob_client).to receive(:list_all_blobs).with(expected_params)
      subject
    end
  end

  describe '#object_pool' do
    subject { repository.object_pool }

    context 'without object pool' do
      it { is_expected.to be_nil }
    end

    context 'when pool repository exists' do
      let!(:pool) { create(:pool_repository, :ready, source_project: project) }

      it { is_expected.to be_nil }

      context 'when repository is linked to the pool repository' do
        before do
          pool.link_repository(pool.source_project.repository)
        end

        it 'returns a object pool for the repository' do
          is_expected.to be_kind_of(Gitaly::ObjectPool)
        end
      end
    end
  end

  describe '#object_format' do
    subject { repository.object_format }

    context 'for SHA1 repository' do
      it { is_expected.to eq :OBJECT_FORMAT_SHA1 }
    end

    context 'for SHA256 repository' do
      let(:project) { create(:project, :empty_repo, object_format: Repository::FORMAT_SHA256) }
      let(:repository) { project.repository.raw }

      it { is_expected.to eq :OBJECT_FORMAT_SHA256 }
    end

    context 'for removed repository' do
      let(:repository) { mutable_repository }

      before do
        repository.remove
      end

      it { expect { subject }.to raise_error(Gitlab::Git::Repository::NoRepository) }
    end
  end

  describe '#get_file_attributes' do
    let(:rev) { 'master' }
    let(:paths) { ['file.txt'] }
    let(:attrs) { ['text'] }

    it_behaves_like 'wrapping gRPC errors', Gitlab::GitalyClient::RepositoryService, :get_file_attributes do
      subject { repository.get_file_attributes(rev, paths, attrs) }
    end
  end

  describe '#detect_generated_files' do
    let(:project) do
      create(:project, :custom_repo, files: {
        '.gitattributes' => gitattr_content,
        'file1.txt' => 'first file',
        'file2.txt' => 'second file'
      })
    end

    let(:gitattr_content) { "" }

    let(:repository) { project.repository.raw }
    let(:base) { project.default_branch }
    let(:branch) { 'detect-generated-files-test' }
    let(:head) { branch }
    let(:paths) do
      [
        Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: 'file1.txt', old_mode: '100644', new_mode: '100644'),
        Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'file2.txt', old_mode: '100644', new_mode: '8')
      ]
    end

    before do
      project.repository.create_branch(branch, project.default_branch)

      project.repository.update_file(
        project.creator,
        'file1.txt',
        'updated first file',
        message: 'Update file',
        branch_name: branch)

      project.repository.delete_file(
        project.creator,
        'file2.txt',
        message: 'Delete file',
        branch_name: branch)
    end

    subject(:generated_files) { repository.detect_generated_files(base, head, paths) }

    context 'when the linguist-generated attribute is used' do
      let(:gitattr_content) { "*.txt text\nfile1.txt linguist-generated\n" }

      it 'returns generated files only' do
        expect(generated_files).to contain_exactly('file1.txt')
      end
    end

    context 'when the gitlab-generated attribute is used' do
      let(:gitattr_content) { "*.txt text\nfile1.txt gitlab-generated\n" }

      it 'returns generated files only' do
        expect(generated_files).to contain_exactly('file1.txt')
      end
    end

    context 'when both linguist-generated and gitlab-generated attribute are used' do
      let(:gitattr_content) { "*.txt text\nfile1.txt linguist-generated gitlab-generated\n" }

      it 'returns generated files only' do
        expect(generated_files).to contain_exactly('file1.txt')
      end
    end

    context 'when the gitlab-generated attribute is used to unset' do
      let(:gitattr_content) { "file1.txt -gitlab-generated\n" }

      it 'returns an empty set' do
        expect(generated_files).to eq Set.new
      end
    end

    context 'with an automatically detected file' do
      before do
        project.repository.create_file(
          project.creator,
          'package-lock.json',
          'generated file content',
          message: 'Add generated file',
          branch_name: branch)
      end

      let(:paths) do
        [
          Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: 'file1.txt', old_mode: '100644', new_mode: '100644'),
          Gitlab::Git::ChangedPath.new(status: :DELETED, path: 'file2.txt', old_mode: '100644', new_mode: '100644'),
          Gitlab::Git::ChangedPath.new(status: :ADDED, path: 'package-lock.json', old_mode: '0', new_mode: '100644')
        ]
      end

      context 'when the manual override is used on non-detectable file' do
        let(:gitattr_content) { "file1.txt gitlab-generated\n" }

        it 'returns both manually overriden file and the detected file' do
          expect(generated_files).to contain_exactly('file1.txt', 'package-lock.json')
        end
      end

      context 'when the manual override is used on the detectable file' do
        let(:gitattr_content) { "package-lock.json gitlab-generated\n" }

        it 'returns the overriden file' do
          expect(generated_files).to contain_exactly('package-lock.json')
        end
      end

      context 'when the manual override is used on the detectable file to unset' do
        let(:gitattr_content) { "package-lock.json -gitlab-generated\n" }

        it 'returns an empty set' do
          expect(generated_files).to eq Set.new
        end
      end

      shared_examples 'an invalid request' do
        let(:exception_class) { Gitlab::Git::CommandError }

        it 'returns an empty set' do
          expect(generated_files).to eq Set.new
        end

        it 'reports the exception' do
          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception)
            .with(
              instance_of(exception_class),
              gl_project_path: repository.gl_project_path,
              base: base,
              head: head,
              paths_count: paths.count,
              paths_bytesize: paths.map(&:path).join.bytesize
            )

          generated_files
        end
      end

      context 'when an unknown revision is given' do
        let(:head) { 'unknownrevision' }

        it_behaves_like 'an invalid request'
      end

      context 'when an unknown path is given' do
        let(:paths) do
          [
            Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: 'file1.txt', old_mode: '100644', new_mode: '100644'),
            Gitlab::Git::ChangedPath.new(status: :MODIFIED, path: 'unknownpath', old_mode: '100644', new_mode: '100644')
          ]
        end

        it_behaves_like 'an invalid request'
      end

      context 'when an Gitlab::Git::ResourceExhaustedError is raised' do
        let(:exception_class) { Gitlab::Git::ResourceExhaustedError }

        before do
          allow(repository).to receive(:get_file_attributes).and_raise(exception_class)
        end

        it_behaves_like 'an invalid request'
      end

      context 'when the size of changed paths exceeds the diff_max_files limit' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:diff_max_files).and_return(2)
        end

        it 'returns an empty set' do
          expect(generated_files).to eq Set.new
        end
      end
    end

    context 'when all files are marked as generated' do
      let(:gitattr_content) { "*.txt gitlab-generated\n" }

      it 'returns all generated files' do
        expect(generated_files).to eq paths.map(&:path).to_set
      end
    end

    context 'when empty paths are given' do
      let(:paths) { [] }
      let(:gitattr_content) { "*.txt gitlab-generated\n" }

      it 'returns an empty set' do
        expect(generated_files).to eq Set.new
      end
    end

    context 'when no generated overrides are used' do
      let(:gitattr_content) { "*.txt text\n" }

      it 'returns an empty set' do
        expect(generated_files).to eq Set.new
      end
    end
  end

  describe '#diffs_by_changed_path' do
    let(:changed_paths) do
      [
        Gitlab::Git::ChangedPath.new(
          status: :ADDED, path: "added_file.rb", old_path: '', old_mode: "0", new_mode: "100644",
          old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '470ad2fcf1e33798f1afc5781d08e60c40f51e7a'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :RENAMED, path: "renamed_file.rb", old_path: 'original_file.rb', old_mode: "100644", new_mode: "100644",
          old_blob_id: '93e123ac8a3e6a0b600953d7598af629dec7b735', new_blob_id: '50b27c6518be44c42c4d87966ae2481ce895624c'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :MODIFIED, path: "modified_file.rb", old_path: '', old_mode: "100644", new_mode: "100644",
          old_blob_id: 'fdaada1754989978413d618ee1fb1c0469d6a664', new_blob_id: '0792c58905eff3432b721f8c4a64363d8e28d9ae'
        ),
        Gitlab::Git::ChangedPath.new(
          status: :DELETED, path: "deleted_file.rb", old_path: '', old_mode: "100644", new_mode: "0",
          old_blob_id: '79bceae69cb5750d6567b223597999bfa91cb3b9', new_blob_id: '0000000000000000000000000000000000000000'
        )
      ]
    end

    let(:diff_refs) do
      Gitlab::Diff::DiffRefs.new(
        base_sha: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
        head_sha: "874797c3a73b60d2187ed6e2fcabd289ff75171e"
      )
    end

    let(:blob_pairs) do
      changed_paths.map do |changed_path|
        Gitaly::DiffBlobsRequest::BlobPair.new(
          left_blob: changed_path.old_blob_id,
          right_blob: changed_path.new_blob_id
        )
      end
    end

    let(:diff_blobs) do
      changed_paths.map do |changed_path|
        Gitlab::GitalyClient::DiffBlob.new(
          left_blob_id: changed_path.old_blob_id,
          right_blob_id: changed_path.new_blob_id,
          patch: 'some content'
        )
      end
    end

    before do
      allow(repository).to receive(:find_changed_paths)
        .once
        .with([kind_of(Gitlab::Git::DiffTree)], find_renames: true)
        .and_return(changed_paths)
    end

    context 'diff file count is smaller than the default batch size' do
      before do
        allow(repository).to receive(:diff_blobs)
          .once
          .with(blob_pairs, anything)
          .and_return(diff_blobs)
      end

      it 'returns diff filess in batches' do
        diff_files = []

        repository.diffs_by_changed_paths(diff_refs, 0) do |batch|
          diff_files << batch
        end

        expect(diff_files.count).to eq 1

        first_batch = diff_files[0]

        expect(first_batch.count).to eq 4
        expect(first_batch[0].new_path).to eq 'added_file.rb'
        expect(first_batch[0].new_file?).to eq true
        expect(first_batch[1].new_path).to eq 'renamed_file.rb'
        expect(first_batch[1].renamed_file?).to eq true
        expect(first_batch[2].new_path).to eq 'modified_file.rb'
        expect(first_batch[2].new_file?).to eq false
        expect(first_batch[3].new_path).to eq 'deleted_file.rb'
        expect(first_batch[3].deleted_file?).to eq true
      end
    end

    context 'offset is given' do
      before do
        allow(repository).to receive(:diff_blobs)
          .once
          .with(blob_pairs[3..], anything)
          .and_return(diff_blobs[3..])
      end

      it 'returns diff filess in batches' do
        diff_files = []

        repository.diffs_by_changed_paths(diff_refs, 3) do |batch|
          diff_files << batch
        end

        expect(diff_files.count).to eq 1

        first_batch = diff_files[0]

        expect(first_batch.count).to eq 1
        expect(first_batch[0].new_path).to eq 'deleted_file.rb'
        expect(first_batch[0].deleted_file?).to eq true
      end
    end

    context 'batch_size is given' do
      before do
        allow(repository).to receive(:diff_blobs)
          .once
          .with(blob_pairs[..1], anything)
          .and_return(diff_blobs[..1])

        allow(repository).to receive(:diff_blobs)
          .once
          .with(blob_pairs[2..], anything)
          .and_return(diff_blobs[2..])
      end

      it 'returns diff filess in batches' do
        diff_files = []

        repository.diffs_by_changed_paths(diff_refs, 0, 2) do |batch|
          diff_files << batch
        end

        expect(diff_files.count).to eq 2

        first_batch = diff_files[0]
        second_batch = diff_files[1]

        expect(first_batch.count).to eq 2
        expect(first_batch[0].new_path).to eq 'added_file.rb'
        expect(first_batch[0].new_file?).to eq true
        expect(first_batch[1].new_path).to eq 'renamed_file.rb'
        expect(first_batch[1].renamed_file?).to eq true
        expect(second_batch.count).to eq 2
        expect(second_batch[0].new_path).to eq 'modified_file.rb'
        expect(second_batch[0].new_file?).to eq false
        expect(second_batch[1].new_path).to eq 'deleted_file.rb'
        expect(second_batch[1].deleted_file?).to eq true
      end
    end

    context 'with submodules' do
      let(:regular_changed_path) do
        [
          Gitlab::Git::ChangedPath.new(
            status: :ADDED, path: "added_file.rb", old_path: '', old_mode: "0", new_mode: "100644",
            old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '470ad2fcf1e33798f1afc5781d08e60c40f51e7a'
          ),
          Gitlab::Git::ChangedPath.new(
            status: :ADDED, path: ".gitmodules", old_path: ".gitmodules", old_mode: "0", new_mode: "100644",
            old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '0fdd9b6f2451a4c35ef4c05bcc0cb017d152a7e9'
          )
        ]
      end

      let(:submodule_changed_path) do
        [
          Gitlab::Git::ChangedPath.new(
            status: :ADDED, path: "gitlab-shell", old_path: 'gitlab-shell', old_mode: "0", new_mode: "160000",
            old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '41e7648c55978e526752c69bdaeaaaa3b45b314b'
          )
        ]
      end

      let(:changed_paths) do
        regular_changed_path + submodule_changed_path
      end

      let(:blob_pairs) do
        regular_changed_path.map do |changed_path|
          Gitaly::DiffBlobsRequest::BlobPair.new(
            left_blob: changed_path.old_blob_id,
            right_blob: changed_path.new_blob_id
          )
        end
      end

      let(:diff_blobs) do
        regular_changed_path.map do |changed_path|
          Gitlab::GitalyClient::DiffBlob.new(
            left_blob_id: changed_path.old_blob_id,
            right_blob_id: changed_path.new_blob_id,
            patch: 'some content'
          )
        end
      end

      before do
        allow(repository).to receive(:diff_blobs)
          .once
          .with(blob_pairs, anything)
          .and_return(diff_blobs)
      end

      it 'returns diff files including submodules' do
        diff_files = []

        repository.diffs_by_changed_paths(diff_refs, 0) do |batch|
          diff_files << batch
        end

        expect(diff_files.count).to eq 1

        first_batch = diff_files[0]

        expect(first_batch.count).to eq 3
        expect(first_batch[0].new_path).to eq 'added_file.rb'
        expect(first_batch[0].new_file?).to eq true
        expect(first_batch[1].new_path).to eq '.gitmodules'
        expect(first_batch[1].new_file?).to eq true
        expect(first_batch[2].new_path).to eq 'gitlab-shell'
        expect(first_batch[2].new_file?).to eq true
        expect(first_batch[2].diff.diff).to eq "+ Subproject commit 41e7648c55978e526752c69bdaeaaaa3b45b314b"
      end

      context 'when submodule is modified' do
        let(:regular_changed_path) { [] }
        let(:submodule_changed_path) do
          [
            Gitlab::Git::ChangedPath.new(
              status: :MODIFIED, path: "gitlab-shell", old_path: '', old_mode: "160000", new_mode: "160000",
              old_blob_id: '41e7648c55978e526752c69bdaeaaaa3b45b314b', new_blob_id: '36b096e40ae7aaa37d85a9038c007f8e70761e64'
            )
          ]
        end

        it 'returns diff files including submodules' do
          diff_files = []

          repository.diffs_by_changed_paths(diff_refs, 0) do |batch|
            diff_files << batch
          end

          expect(diff_files.count).to eq 1

          first_batch = diff_files[0]

          expect(first_batch.count).to eq 1
          expect(first_batch[0].diff.diff).to eq "- Subproject commit 41e7648c55978e526752c69bdaeaaaa3b45b314b\n+ Subproject commit 36b096e40ae7aaa37d85a9038c007f8e70761e64"
        end
      end

      context 'when submodule is deleted' do
        let(:regular_changed_path) do
          [
            Gitlab::Git::ChangedPath.new(
              status: :DELETED, path: ".gitmodules", old_path: '', old_mode: "100644", new_mode: "0",
              old_blob_id: '79bceae69cb5750d6567b223597999bfa91cb3b9', new_blob_id: '0000000000000000000000000000000000000000'
            )
          ]
        end

        let(:submodule_changed_path) do
          [
            Gitlab::Git::ChangedPath.new(
              status: :DELETED, path: "gitlab-shell", old_path: '', old_mode: "160000", new_mode: "0",
              old_blob_id: '41e7648c55978e526752c69bdaeaaaa3b45b314b', new_blob_id: '0000000000000000000000000000000000000000'
            )
          ]
        end

        it 'returns diff files including submodules' do
          diff_files = []

          repository.diffs_by_changed_paths(diff_refs, 0) do |batch|
            diff_files << batch
          end

          expect(diff_files.count).to eq 1

          first_batch = diff_files[0]

          expect(first_batch.count).to eq 2
          expect(first_batch[0].new_path).to eq '.gitmodules'
          expect(first_batch[0].deleted_file?).to eq true
          expect(first_batch[1].new_path).to eq 'gitlab-shell'
          expect(first_batch[1].deleted_file?).to eq true
          expect(first_batch[1].diff.diff).to eq "- Subproject commit 41e7648c55978e526752c69bdaeaaaa3b45b314b"
        end
      end
    end
  end

  describe '#gitaly_diff_client' do
    it 'instantiates a new DiffService class' do
      expect(repository.gitaly_diff_client).to be_a(Gitlab::GitalyClient::DiffService)
    end
  end

  describe '#cherry_pick' do
    let(:commit) { mutable_repository.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }
    let(:target_sha) { mutable_repository.commit.id }
    let(:args) do
      {
        user: user,
        message: 'message',
        commit: commit,
        branch_name: 'master',
        target_sha: target_sha,
        start_branch_name: 'master',
        start_repository: mutable_repository
      }
    end

    subject(:cherry_pick) do
      mutable_repository.cherry_pick(**args)
    end

    it 'delegates to user_cherry_pick' do
      expect_next_instance_of(Gitlab::GitalyClient::OperationService) do |service|
        expect(service).to receive(:user_cherry_pick).with(a_hash_including(args)).and_call_original
      end

      cherry_pick
    end

    context 'when target_sha does not exist' do
      let(:target_sha) { '0000000000000000000000000000000000000000' }

      it 'raises an error' do
        expect { cherry_pick }.to raise_error(Gitlab::Git::CommandError)
      end
    end

    context 'when branch changes after target sha' do
      before do
        target_sha
        mutable_project.repository.create_file(user, 'somefile', '', message: 'add a file', branch_name: 'master')
      end

      it 'raises an error' do
        expect { cherry_pick }.to raise_error(Gitlab::Git::CommandError)
      end
    end
  end
end
