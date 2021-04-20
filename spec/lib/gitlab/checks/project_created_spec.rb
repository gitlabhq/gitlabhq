# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ProjectCreated, :clean_gitlab_redis_shared_state do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  let(:protocol) { 'http' }
  let(:git_user) { user }
  let(:repository) { project.repository }

  subject { described_class.new(repository, git_user, 'http') }

  describe '.fetch_message' do
    context 'with a project created message queue' do
      before do
        subject.add_message
      end

      it 'returns project created message' do
        expect(described_class.fetch_message(user.id, project.id)).to eq(subject.message)
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
      expect(subject.add_message).to eq('OK')
    end

    context 'when user is nil' do
      let(:git_user) { nil }

      it 'handles anonymous push' do
        expect(subject.add_message).to be_nil
      end
    end
  end
end
