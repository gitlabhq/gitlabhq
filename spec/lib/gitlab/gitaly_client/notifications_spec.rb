require 'spec_helper'

describe Gitlab::GitalyClient::Notifications do
  let(:client) { Gitlab::GitalyClient::Notifications.new }

  before do
    allow(Gitlab.config.gitaly).to receive(:socket_path).and_return('path/to/gitaly.socket')
  end

  describe '#post_receive' do
    let(:repo_path) { '/path/to/my_repo.git' }

    it 'sends a post_receive message' do
      expect_any_instance_of(Gitaly::Notifications::Stub).
        to receive(:post_receive).with(post_receive_request_with_repo_path(repo_path))

      client.post_receive(repo_path)
    end
  end
end
