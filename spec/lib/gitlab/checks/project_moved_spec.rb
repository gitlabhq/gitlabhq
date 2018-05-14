require 'rails_helper'

describe Gitlab::Checks::ProjectMoved, :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '.fetch_message' do
    context 'with a redirect message queue' do
      it 'returns the redirect message' do
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        project_moved.add_message

        expect(described_class.fetch_message(user.id, project.id)).to eq(project_moved.message)
      end

      it 'deletes the redirect message from redis' do
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        project_moved.add_message

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("redirect_namespace:#{user.id}:#{project.id}") }).not_to be_nil
        described_class.fetch_message(user.id, project.id)
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("redirect_namespace:#{user.id}:#{project.id}") }).to be_nil
      end
    end

    context 'with no redirect message queue' do
      it 'returns nil' do
        expect(described_class.fetch_message(1, 2)).to be_nil
      end
    end
  end

  describe '#add_message' do
    it 'queues a redirect message' do
      project_moved = described_class.new(project, user, 'http', 'foo/bar')
      expect(project_moved.add_message).to eq("OK")
    end

    it 'handles anonymous clones' do
      project_moved = described_class.new(project, nil, 'http', 'foo/bar')

      expect(project_moved.add_message).to eq(nil)
    end
  end

  describe '#message' do
    it 'returns a redirect message' do
      project_moved = described_class.new(project, user, 'http', 'foo/bar')
      message = <<~MSG
                Project 'foo/bar' was moved to '#{project.full_path}'.

                Please update your Git remote:

                  git remote set-url origin #{project.http_url_to_repo}
                MSG

      expect(project_moved.message).to eq(message)
    end
  end
end
