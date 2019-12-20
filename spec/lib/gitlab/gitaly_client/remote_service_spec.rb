# frozen_string_literal: true

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
    let(:remote_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '', 'group/project') }

    it 'sends an fetch_internal_remote message and returns the result value' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:fetch_internal_remote)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(result: true))

      expect(client.fetch_internal_remote(remote_repository)).to be(true)
    end
  end

  describe '#find_remote_root_ref' do
    it 'sends an find_remote_root_ref message and returns the root ref' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:find_remote_root_ref)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(ref: 'master'))

      expect(client.find_remote_root_ref('origin')).to eq 'master'
    end

    it 'ensure ref is a valid UTF-8 string' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:find_remote_root_ref)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(ref: "an_invalid_ref_\xE5"))

      expect(client.find_remote_root_ref('origin')).to eq "an_invalid_ref_å"
    end
  end

  describe '#update_remote_mirror' do
    let(:ref_name) { 'remote_mirror_1' }
    let(:only_branches_matching) { %w[my-branch master] }
    let(:ssh_key) { 'KEY' }
    let(:known_hosts) { 'KNOWN HOSTS' }

    it 'sends an update_remote_mirror message' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:update_remote_mirror)
        .with(kind_of(Enumerator), kind_of(Hash))
        .and_return(double(:update_remote_mirror_response))

      client.update_remote_mirror(ref_name, only_branches_matching, ssh_key: ssh_key, known_hosts: known_hosts)
    end
  end

  describe '.exists?' do
    context "when the remote doesn't exist" do
      let(:url) { 'https://gitlab.com/gitlab-org/ik-besta-niet-of-ik-word-geplaagd.git' }

      it 'returns false' do
        expect(described_class.exists?(url)).to be(false)
      end
    end
  end
end
