require 'spec_helper'

describe Gitlab::GitalyClient::RemoteService do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:remote_name) { 'my-remote' }
  let(:client) { described_class.new(project.repository) }

  describe '#add_remote' do
    let(:url) { 'http://my-repo.git' }
    let(:mirror_refmap) { :all_refs }

    it 'sends an add_remote message' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:add_remote)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:add_remote_response))

      client.add_remote(remote_name, url, mirror_refmap)
    end
  end

  describe '#remove_remote' do
    it 'sends an remove_remote message and returns the result value' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:remove_remote)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(result: true))

      expect(client.remove_remote(remote_name)).to be(true)
    end
  end

  describe '#fetch_internal_remote' do
    let(:remote_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '') }

    it 'sends an fetch_internal_remote message and returns the result value' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:fetch_internal_remote)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(result: true))

      expect(client.fetch_internal_remote(remote_repository)).to be(true)
    end
  end

  describe '#update_remote_mirror' do
    let(:ref_name) { 'remote_mirror_1' }
    let(:only_branches_matching) { ['my-branch', 'master'] }

    it 'sends an update_remote_mirror message' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:update_remote_mirror)
        .with(kind_of(Enumerator), kind_of(Hash))
        .and_return(double(:update_remote_mirror_response))

      client.update_remote_mirror(ref_name, only_branches_matching)
    end
  end
end
