require 'rails_helper'

describe Gitlab::Checks::NewProject, :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '.fetch_new_project_message' do
    context 'with a new project message queue' do
      let(:new_project) { described_class.new(user, project, 'http') }

      before do
        new_project.add_new_project_message
      end

      it 'returns new project message' do
        expect(described_class.fetch_new_project_message(user.id, project.id)).to eq(new_project.new_project_message)
      end

      it 'deletes the new project message from redis' do
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("new_project:#{user.id}:#{project.id}") }).not_to be_nil
        described_class.fetch_new_project_message(user.id, project.id)
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get("new_project:#{user.id}:#{project.id}") }).to be_nil
      end
    end

    context 'with no new project message queue' do
      it 'returns nil' do
        expect(described_class.fetch_new_project_message(1, 2)).to be_nil
      end
    end
  end

  describe '#add_new_project_message' do
    it 'queues a new project message' do
      new_project = described_class.new(user, project, 'http')

      expect(new_project.add_new_project_message).to eq('OK')
    end

    it 'handles anonymous push' do
      new_project = described_class.new(user, nil, 'http')

      expect(new_project.add_new_project_message).to be_nil
    end
  end
end
