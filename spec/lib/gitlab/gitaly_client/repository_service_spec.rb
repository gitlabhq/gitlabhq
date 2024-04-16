# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::RepositoryService, feature_category: :gitaly do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#exists?' do
    it 'sends a repository_exists message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repository_exists)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(exists: true))

      client.exists?
    end
  end

  describe '#optimize_repository' do
    shared_examples 'a repository optimization' do
      it 'sends a optimize_repository message' do
        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:optimize_repository)
          .with(gitaly_request_with_params(
            strategy: expected_strategy
          ), kind_of(Hash))
          .and_call_original

        client.optimize_repository(**params)
      end
    end

    context 'with default parameter' do
      let(:params) { {} }
      let(:expected_strategy) { :STRATEGY_HEURISTICAL }

      it_behaves_like 'a repository optimization'
    end

    context 'with heuristical housekeeping strategy' do
      let(:params) { { eager: false } }
      let(:expected_strategy) { :STRATEGY_HEURISTICAL }

      it_behaves_like 'a repository optimization'
    end

    context 'with eager housekeeping strategy' do
      let(:params) { { eager: true } }
      let(:expected_strategy) { :STRATEGY_EAGER }

      it_behaves_like 'a repository optimization'
    end
  end

  describe '#prune_unreachable_objects' do
    it 'sends a prune_unreachable_objects message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:prune_unreachable_objects)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:prune_unreachable_objects))

      client.prune_unreachable_objects
    end
  end

  describe '#repository_size' do
    it 'sends a repository_size message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repository_size)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(size: 0)

      client.repository_size
    end
  end

  describe '#repository_info' do
    it 'sends a repository_info message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repository_info)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_call_original

      response = client.repository_info

      expect(response.size).to be_an(Integer)
      expect(response.references).to be_a(Gitaly::RepositoryInfoResponse::ReferencesInfo)
      expect(response.objects).to be_a(Gitaly::RepositoryInfoResponse::ObjectsInfo)
    end
  end

  describe '#get_object_directory_size' do
    it 'sends a get_object_directory_size message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_object_directory_size)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(size: 0)

      client.get_object_directory_size
    end
  end

  describe '#info_attributes' do
    it 'reads the info attributes' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_info_attributes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.info_attributes
    end
  end

  describe '#has_local_branches?' do
    it 'sends a has_local_branches message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:has_local_branches)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(value: true))

      expect(client.has_local_branches?).to be(true)
    end
  end

  describe '#fork_repository' do
    let(:source_repository) { Gitlab::Git::Repository.new('default', 'repo/path', '', 'group/project') }

    context 'when branch is not provided' do
      it 'sends a create_fork message' do
        expected_request = gitaly_request_with_params(
          source_repository: source_repository.gitaly_repository,
          revision: ""
        )

        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:create_fork)
          .with(expected_request, kind_of(Hash))
          .and_return(double(value: true))

        client.fork_repository(source_repository)
      end
    end

    context 'when branch is provided' do
      it 'sends a create_fork message including revision' do
        branch = 'wip'

        expected_request = gitaly_request_with_params(
          source_repository: source_repository.gitaly_repository,
          revision: "refs/heads/#{branch}"
        )

        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:create_fork)
          .with(expected_request, kind_of(Hash))
          .and_return(double(value: true))

        client.fork_repository(source_repository, branch)
      end
    end
  end

  describe '#import_repository' do
    let(:source) { 'https://example.com/git/repo.git' }

    it 'sends a create_repository_from_url message' do
      expected_request = gitaly_request_with_params(
        url: source,
        resolved_address: ''
      )

      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository_from_url)
        .with(expected_request, kind_of(Hash))
        .and_return(double(value: true))

      client.import_repository(source)
    end

    context 'when http_host is provided' do
      it 'sends a create_repository_from_url message with http_host provided in the request' do
        expected_request = gitaly_request_with_params(
          url: source,
          resolved_address: '172.16.123.1'
        )

        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:create_repository_from_url)
          .with(expected_request, kind_of(Hash))
          .and_return(double(value: true))

        client.import_repository(source, resolved_address: '172.16.123.1')
      end
    end
  end

  describe '#fetch_remote' do
    let(:url) { 'https://example.com/git/repo.git' }

    it 'sends a fetch_remote_request message' do
      expected_request = gitaly_request_with_params(
        remote_params: Gitaly::Remote.new(
          url: url,
          http_authorization_header: "",
          mirror_refmaps: [],
          resolved_address: ''
        ),
        ssh_key: '',
        known_hosts: '',
        force: false,
        no_tags: false,
        no_prune: false,
        check_tags_changed: false
      )

      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:fetch_remote)
        .with(expected_request, kind_of(Hash))
        .and_return(double(value: true))

      client.fetch_remote(url, refmap: nil, ssh_auth: nil, forced: false, no_tags: false, timeout: 1, check_tags_changed: false)
    end

    context 'with resolved address' do
      it 'sends a fetch_remote_request message' do
        expected_request = gitaly_request_with_params(
          remote_params: Gitaly::Remote.new(
            url: url,
            http_authorization_header: "",
            mirror_refmaps: [],
            resolved_address: '172.16.123.1'
          ),
          ssh_key: '',
          known_hosts: '',
          force: false,
          no_tags: false,
          no_prune: false,
          check_tags_changed: false
        )

        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:fetch_remote)
          .with(expected_request, kind_of(Hash))
          .and_return(double(value: true))

        client.fetch_remote(url, refmap: nil, ssh_auth: nil, forced: false, no_tags: false, timeout: 1, check_tags_changed: false, resolved_address: '172.16.123.1')
      end
    end

    context 'SSH auth' do
      where(:ssh_mirror_url, :ssh_key_auth, :ssh_private_key, :ssh_known_hosts, :expected_params) do
        false | false | 'key' | 'known_hosts' | {}
        false | true  | 'key' | 'known_hosts' | {}
        true  | false | 'key' | 'known_hosts' | { known_hosts: 'known_hosts' }
        true  | true  | 'key' | 'known_hosts' | { ssh_key: 'key', known_hosts: 'known_hosts' }
        true  | true  | 'key' | nil           | { ssh_key: 'key' }
        true  | true  | nil   | 'known_hosts' | { known_hosts: 'known_hosts' }
        true  | true  | nil   | nil           | {}
        true  | true  | ''    | ''            | {}
      end

      with_them do
        let(:ssh_auth) do
          double(
            :ssh_auth,
            ssh_mirror_url?: ssh_mirror_url,
            ssh_key_auth?: ssh_key_auth,
            ssh_private_key: ssh_private_key,
            ssh_known_hosts: ssh_known_hosts
          )
        end

        it do
          expected_request = gitaly_request_with_params({
            remote_params: Gitaly::Remote.new(
              url: url,
              http_authorization_header: "",
              mirror_refmaps: []
            ),
            ssh_key: '',
            known_hosts: '',
            force: false,
            no_tags: false,
            no_prune: false
          }.update(expected_params))

          expect_any_instance_of(Gitaly::RepositoryService::Stub)
            .to receive(:fetch_remote)
            .with(expected_request, kind_of(Hash))
            .and_return(double(value: true))

          client.fetch_remote(url, refmap: nil, ssh_auth: ssh_auth, forced: false, no_tags: false, timeout: 1)
        end
      end
    end
  end

  describe '#calculate_checksum' do
    it 'sends a calculate_checksum message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:calculate_checksum)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(checksum: 0))

      client.calculate_checksum
    end
  end

  describe '#create_repository' do
    it 'sends a create_repository message without arguments' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository)
        .with(gitaly_request_with_path(storage_name, relative_path)
        .and(gitaly_request_with_params(default_branch: '')), kind_of(Hash))
        .and_return(double)

      client.create_repository
    end

    it 'sends a create_repository message with default branch' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository)
        .with(gitaly_request_with_path(storage_name, relative_path)
        .and(gitaly_request_with_params(default_branch: 'default-branch-name')), kind_of(Hash))
        .and_return(double)

      client.create_repository('default-branch-name')
    end

    it 'sends a create_repository message with default branch containing non ascii chars' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository)
        .with(gitaly_request_with_path(storage_name, relative_path)
        .and(gitaly_request_with_params(
          default_branch: Gitlab::EncodingHelper.encode_binary('feature/新機能'))), kind_of(Hash)
        ).and_return(double)

      client.create_repository('feature/新機能')
    end

    context 'when object format is provided' do
      before do
        expect_any_instance_of(Gitaly::RepositoryService::Stub)
          .to receive(:create_repository)
          .with(gitaly_request_with_path(storage_name, relative_path)
          .and(gitaly_request_with_params(default_branch: '', object_format: expected_format)), kind_of(Hash))
          .and_return(double)
      end

      context 'with SHA1 format' do
        let(:expected_format) { :OBJECT_FORMAT_SHA1 }

        it 'sends a create_repository message with object format' do
          client.create_repository(object_format: Repository::FORMAT_SHA1)
        end
      end

      context 'with SHA256 format' do
        let(:expected_format) { :OBJECT_FORMAT_SHA256 }

        it 'sends a create_repository message with object format' do
          client.create_repository(object_format: Repository::FORMAT_SHA256)
        end
      end

      context 'with unknown format' do
        let(:expected_format) { :OBJECT_FORMAT_UNSPECIFIED }

        it 'sends a create_repository message with object format' do
          client.create_repository(object_format: 'unknown')
        end
      end
    end
  end

  describe '#raw_changes_between' do
    it 'sends a get_raw_changes message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_raw_changes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double)

      client.raw_changes_between('deadbeef', 'deadpork')
    end
  end

  describe '#search_files_by_regexp' do
    subject(:result) { client.search_files_by_regexp(ref, '.*') }

    before do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:search_files_by_name)
              .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
              .and_return([double(files: ['file1.txt']), double(files: ['file2.txt'])])
    end

    shared_examples 'a search for files by regexp' do
      it 'sends a search_files_by_name message and returns a flatten array' do
        expect(result).to contain_exactly('file1.txt', 'file2.txt')
      end
    end

    context 'with ASCII ref' do
      let(:ref) { 'master' }

      it_behaves_like 'a search for files by regexp'
    end

    context 'with non-ASCII ref' do
      let(:ref) { 'ref-ñéüçæøß-val' }

      it_behaves_like 'a search for files by regexp'
    end
  end

  describe '#disconnect_alternates' do
    it 'sends a disconnect_git_alternates message' do
      expect_any_instance_of(Gitaly::ObjectPoolService::Stub)
        .to receive(:disconnect_git_alternates)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.disconnect_alternates
    end
  end

  describe '#remove' do
    it 'sends a remove_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:remove_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(value: true))

      client.remove
    end
  end

  describe '#replicate' do
    let(:source_repository) { Gitlab::Git::Repository.new('default', 'repo/path', '', 'group/project') }

    it 'sends a replicate_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:replicate_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.replicate(source_repository)
    end
  end

  describe "#find_license" do
    it 'sends a find_license request with medium timeout' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:find_license) do |_service, _request, headers|
        expect(headers[:deadline]).to be_between(
          Gitlab::GitalyClient.fast_timeout.seconds.from_now.to_f,
          Gitlab::GitalyClient.medium_timeout.seconds.from_now.to_f
        )
      end

      client.find_license
    end
  end

  describe '#object_pool' do
    it 'sends a get_object_pool_request message' do
      expect_any_instance_of(Gitaly::ObjectPoolService::Stub)
        .to receive(:get_object_pool)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.object_pool
    end
  end

  describe '#object_format' do
    it 'sends a object_format message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:object_format)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.object_format
    end
  end

  describe '#get_file_attributes' do
    let(:rev) { 'master' }
    let(:paths) { ['file.txt'] }
    let(:attrs) { ['text'] }

    it 'sends a get_file_attributes message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_file_attributes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_call_original

      expect(client.get_file_attributes(rev, paths, attrs)).to be_a Gitaly::GetFileAttributesResponse
    end
  end
end
