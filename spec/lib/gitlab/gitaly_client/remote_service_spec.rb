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
end
