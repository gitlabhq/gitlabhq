require 'spec_helper'

describe Gitlab::GitalyClient::NotificationService do
  describe '#post_receive' do
    let(:project) { create(:project) }
    let(:storage_name) { project.repository_storage }
    let(:relative_path) { project.disk_path + '.git' }
    subject { described_class.new(project.repository) }

    it 'sends a post_receive message' do
      expect_any_instance_of(Gitaly::NotificationService::Stub)
        .to receive(:post_receive).with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      subject.post_receive
    end
  end
end
