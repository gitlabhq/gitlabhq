require 'spec_helper'

describe Gitlab::GitalyClient::RepositoryService do
  set(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.path_with_namespace + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#exists?' do
    it 'sends an exists message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:exists)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_call_original

      client.exists?
    end
  end
end
