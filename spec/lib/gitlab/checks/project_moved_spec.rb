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
    context 'when the push is rejected' do
      it 'returns a redirect message telling the user to try again' do
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        message = "Project 'foo/bar' was moved to '#{project.full_path}'." +
          "\n\nPlease update your Git remote:" +
          "\n\n  git remote set-url origin #{project.http_url_to_repo} and try again.\n"

        expect(project_moved.message(rejected: true)).to eq(message)
      end
    end

    context 'when the push is not rejected' do
      it 'returns a redirect message' do
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        message = "Project 'foo/bar' was moved to '#{project.full_path}'." +
          "\n\nPlease update your Git remote:" +
          "\n\n  git remote set-url origin #{project.http_url_to_repo}\n"

        expect(project_moved.message).to eq(message)
      end
    end
  end

  describe '#permanent_redirect?' do
    context 'with a permanent RedirectRoute' do
      it 'returns true' do
        project.route.create_redirect('foo/bar', permanent: true)
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        expect(project_moved.permanent_redirect?).to be_truthy
      end
    end

    context 'without a permanent RedirectRoute' do
      it 'returns false' do
        project.route.create_redirect('foo/bar')
        project_moved = described_class.new(project, user, 'http', 'foo/bar')
        expect(project_moved.permanent_redirect?).to be_falsy
      end
    end
  end
end
