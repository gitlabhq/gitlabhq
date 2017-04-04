require 'spec_helper'

describe Gitlab::GitalyClient::Notifications do
  describe '#post_receive' do
    it 'sends a post_receive message' do
      repo_path = create(:empty_project).repository.path_to_repo
      expect_any_instance_of(Gitaly::Notifications::Stub).
        to receive(:post_receive).with(post_receive_request_with_repo_path(repo_path))

      described_class.new(repo_path).post_receive
    end
  end
end
