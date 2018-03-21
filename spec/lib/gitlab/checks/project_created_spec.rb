require 'rails_helper'

describe Gitlab::Checks::ProjectCreated, :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '.fetch_message' do
    context 'with a project created message queue' do
      let(:project_created) { described_class.new(project, user, 'http') }

      before do
        project_created.add_message
      end

      it 'returns project created message' do
        expect(described_class.fetch_message(user.id, project.id)).to eq(project_created.message)
      end

      it 'deletes the project created message from redis' do
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("project_created:#{user.id}:#{project.id}") }).not_to be_nil
        described_class.fetch_message(user.id, project.id)
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("project_created:#{user.id}:#{project.id}") }).to be_nil
      end
    end

    context 'with no project created message queue' do
      it 'returns nil' do
        expect(described_class.fetch_message(1, 2)).to be_nil
      end
    end
  end

  describe '#add_message' do
    it 'queues a project created message' do
      project_created = described_class.new(project, user, 'http')

      expect(project_created.add_message).to eq('OK')
    end

    it 'handles anonymous push' do
      project_created = described_class.new(nil, user, 'http')

      expect(project_created.add_message).to be_nil
    end
  end
end
