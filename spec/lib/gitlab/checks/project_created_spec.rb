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
    let(:key) { "project_created:#{user.id}:#{project.repository.gl_repository}" }
    let(:legacy_key) { "project_created:#{user.id}:#{project.id}" }

    context 'with a project created message queue' do
      before do
        subject.add_message
      end

      it 'returns project created message' do
        expect(described_class.fetch_message(user, project.repository)).to eq(subject.message)
      end

      it 'deletes the project created message from redis' do
        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(key) }).not_to be_nil

        described_class.fetch_message(user, project.repository)

        expect(Gitlab::Redis::SharedState.with { |redis| redis.get(key) }).to be_nil
      end

      context 'with a message in the legacy key' do
        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(legacy_key, 'legacy message')
          end
        end

        it 'returns and deletes the legacy message' do
          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(key) }).not_to be_nil
          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(legacy_key) }).not_to be_nil

          expect(described_class.fetch_message(user, project.repository)).to eq('legacy message')

          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(key) }).to be_nil
          expect(Gitlab::Redis::SharedState.with { |redis| redis.get(legacy_key) }).to be_nil
        end
      end
    end

    context 'with no project created message queue' do
      it 'returns nil' do
        expect(described_class.fetch_message(user, project.repository)).to be_nil
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
