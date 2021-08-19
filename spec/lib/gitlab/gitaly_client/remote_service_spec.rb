# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::RemoteService do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#find_remote_root_ref' do
    let(:url) { 'http://git.example.com/my-repo.git' }
    let(:auth) { 'Basic secret' }
    let(:expected_params) { { remote_url: url, http_authorization_header: auth } }

    it 'sends an find_remote_root_ref message and returns the root ref' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:find_remote_root_ref)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .with(gitaly_request_with_params(expected_params), kind_of(Hash))
        .and_return(double(ref: 'master'))

      expect(client.find_remote_root_ref(url, auth)).to eq 'master'
    end

    it 'ensure ref is a valid UTF-8 string' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:find_remote_root_ref)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .with(gitaly_request_with_params(expected_params), kind_of(Hash))
        .and_return(double(ref: "an_invalid_ref_\xE5"))

      expect(client.find_remote_root_ref(url, auth)).to eq "an_invalid_ref_å"
    end
  end

  describe '#update_remote_mirror' do
    let(:only_branches_matching) { %w[my-branch master] }
    let(:ssh_key) { 'KEY' }
    let(:known_hosts) { 'KNOWN HOSTS' }
    let(:url) { 'http:://git.example.com/my-repo.git' }
    let(:expected_params) { { remote: Gitaly::UpdateRemoteMirrorRequest::Remote.new(url: url) } }

    it 'sends an update_remote_mirror message' do
      expect_any_instance_of(Gitaly::RemoteService::Stub)
        .to receive(:update_remote_mirror)
        .with(array_including(gitaly_request_with_params(expected_params)), kind_of(Hash))
        .and_return(double(:update_remote_mirror_response))

      client.update_remote_mirror(url, only_branches_matching, ssh_key: ssh_key, known_hosts: known_hosts, keep_divergent_refs: true)
    end
  end

  describe '.exists?' do
    context "when the remote doesn't exist" do
      let(:url) { 'https://gitlab.com/gitlab-org/ik-besta-niet-of-ik-word-geplaagd.git' }
      let(:storage_name) { 'default' }

      it 'returns false' do
        expect(Gitaly::FindRemoteRepositoryRequest).to receive(:new).with(remote: url, storage_name: storage_name).and_call_original

        expect(described_class.exists?(url)).to be(false)
      end
    end
  end
end
