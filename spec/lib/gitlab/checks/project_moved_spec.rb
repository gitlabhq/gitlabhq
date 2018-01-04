require 'rails_helper'

describe Gitlab::Checks::ProjectMoved, :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '.fetch_redirct_message' do
    context 'with a redirect message queue' do
      it 'should return the redirect message' do
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        project_moved.add_redirect_message

        expect(described_class.fetch_redirect_message(user.id, project.id)).to eq(project_moved.redirect_message)
      end

      it 'should delete the redirect message from redis' do
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        project_moved.add_redirect_message

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("redirect_namespace:#{user.id}:#{project.id}") }).not_to be_nil
        described_class.fetch_redirect_message(user.id, project.id)
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("redirect_namespace:#{user.id}:#{project.id}") }).to be_nil
      end
    end

    context 'with no redirect message queue' do
      it 'should return nil' do
        expect(described_class.fetch_redirect_message(1, 2)).to be_nil
      end
    end
  end

  describe '#add_redirect_message' do
    it 'should queue a redirect message' do
      project_moved = described_class.new(project, user, 'foo/bar', 'http')
      expect(project_moved.add_redirect_message).to eq("OK")
    end

    it 'should handle anonymous clones' do
      project_moved = described_class.new(project, nil, 'foo/bar', 'http')

      expect(project_moved.add_redirect_message).to eq(nil)
    end
  end

  describe '#redirect_message' do
    context 'when the push is rejected' do
      it 'should return a redirect message telling the user to try again' do
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        message = "Project 'foo/bar' was moved to '#{project.full_path}'." +
          "\n\nPlease update your Git remote:" +
          "\n\n  git remote set-url origin #{project.http_url_to_repo} and try again.\n"

        expect(project_moved.redirect_message(rejected: true)).to eq(message)
      end
    end

    context 'when the push is not rejected' do
      it 'should return a redirect message' do
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        message = "Project 'foo/bar' was moved to '#{project.full_path}'." +
          "\n\nPlease update your Git remote:" +
          "\n\n  git remote set-url origin #{project.http_url_to_repo}\n"

        expect(project_moved.redirect_message).to eq(message)
      end
    end
  end

  describe '#permanent_redirect?' do
    context 'with a permanent RedirectRoute' do
      it 'should return true' do
        project.route.create_redirect('foo/bar', permanent: true)
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        expect(project_moved.permanent_redirect?).to be_truthy
      end
    end

    context 'without a permanent RedirectRoute' do
      it 'should return false' do
        project.route.create_redirect('foo/bar')
        project_moved = described_class.new(project, user, 'foo/bar', 'http')
        expect(project_moved.permanent_redirect?).to be_falsy
      end
    end
  end
end
