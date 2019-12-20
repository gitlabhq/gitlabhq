# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::RefService do
  let(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:repository) { project.repository }
  let(:client) { described_class.new(repository) }

  describe '#branches' do
    it 'sends a find_all_branches message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_all_branches)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.branches
    end
  end

  describe '#remote_branches' do
    let(:remote_name) { 'my_remote' }

    subject { client.remote_branches(remote_name) }

    it 'sends a find_all_remote_branches message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_all_remote_branches)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      subject
    end

    it 'concantes and returns the response branches as Gitlab::Git::Branch objects' do
      target_commits = create_list(:gitaly_commit, 4)
      response_branches = target_commits.each_with_index.map do |gitaly_commit, i|
        Gitaly::Branch.new(name: "#{remote_name}/#{i}", target_commit: gitaly_commit)
      end
      response = [
        Gitaly::FindAllRemoteBranchesResponse.new(branches: response_branches[0, 2]),
        Gitaly::FindAllRemoteBranchesResponse.new(branches: response_branches[2, 2])
      ]

      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_all_remote_branches).and_return(response)

      expect(subject.length).to be(response_branches.length)

      response_branches.each_with_index do |gitaly_branch, i|
        branch = subject[i]
        commit = Gitlab::Git::Commit.new(repository, gitaly_branch.target_commit)

        expect(branch.name).to eq(i.to_s) # It removes the `remote/` prefix
        expect(branch.dereferenced_target).to eq(commit)
      end
    end
  end

  describe '#branch_names' do
    it 'sends a find_all_branch_names message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_all_branch_names)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.branch_names
    end
  end

  describe '#tag_names' do
    it 'sends a find_all_tag_names message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_all_tag_names)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.tag_names
    end
  end

  describe '#default_branch_name' do
    it 'sends a find_default_branch_name message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_default_branch_name)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(name: 'foo'))

      client.default_branch_name
    end
  end

  describe '#list_new_blobs' do
    it 'raises DeadlineExceeded when timeout is too small' do
      newrev = '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51'

      expect do
        client.list_new_blobs(newrev, dynamic_timeout: 0.001)
      end.to raise_error(GRPC::DeadlineExceeded)
    end
  end

  describe '#local_branches' do
    it 'sends a find_local_branches message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_local_branches)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.local_branches
    end

    it 'parses and sends the sort parameter' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_local_branches)
        .with(gitaly_request_with_params(sort_by: :UPDATED_DESC), kind_of(Hash))
        .and_return([])

      client.local_branches(sort_by: 'updated_desc')
    end

    it 'translates known mismatches on sort param values' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:find_local_branches)
        .with(gitaly_request_with_params(sort_by: :NAME), kind_of(Hash))
        .and_return([])

      client.local_branches(sort_by: 'name_asc')
    end

    it 'raises an argument error if an invalid sort_by parameter is passed' do
      expect { client.local_branches(sort_by: 'invalid_sort') }.to raise_error(ArgumentError)
    end
  end

  describe '#find_ref_name', :seed_helper do
    subject { client.find_ref_name(SeedRepo::Commit::ID, 'refs/heads/master') }

    it { is_expected.to be_utf8 }
    it { is_expected.to eq('refs/heads/master') }
  end

  describe '#ref_exists?', :seed_helper do
    it 'finds the master branch ref' do
      expect(client.ref_exists?('refs/heads/master')).to eq(true)
    end

    it 'returns false for an illegal tag name ref' do
      expect(client.ref_exists?('refs/tags/.this-tag-name-is-illegal')).to eq(false)
    end

    it 'raises an argument error if the ref name parameter does not start with refs/' do
      expect { client.ref_exists?('reXXXXX') }.to raise_error(ArgumentError)
    end
  end

  describe '#delete_refs' do
    let(:prefixes) { %w(refs/heads refs/keep-around) }

    it 'sends a delete_refs message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:delete_refs)
        .with(gitaly_request_with_params(except_with_prefix: prefixes), kind_of(Hash))
        .and_return(double('delete_refs_response', git_error: ""))

      client.delete_refs(except_with_prefixes: prefixes)
    end
  end

  describe '#pack_refs' do
    it 'sends a pack_refs message' do
      expect_any_instance_of(Gitaly::RefService::Stub)
        .to receive(:pack_refs)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:pack_refs_response))

      client.pack_refs
    end
  end
end
