# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ContainerMoved, :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  let(:repository) { project.repository }
  let(:protocol) { 'http' }
  let(:git_user) { user }
  let(:redirect_path) { 'foo/bar' }

  subject { described_class.new(repository, git_user, protocol, redirect_path) }

  describe '.fetch_message' do
    let(:key) { "redirect_namespace:#{user.id}:#{project.repository.gl_repository}" }
    let(:legacy_key) { "redirect_namespace:#{user.id}:#{project.id}" }

    context 'with a redirect message queue' do
      before do
        subject.add_message
      end

      it 'returns the redirect message' do
        expect(described_class.fetch_message(user, project.repository)).to eq(subject.message)
      end

      it 'deletes the redirect message from redis' do
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

    context 'with no redirect message queue' do
      it 'returns nil' do
        expect(described_class.fetch_message(user, project.repository)).to be_nil
      end
    end
  end

  describe '#add_message' do
    it 'queues a redirect message' do
      expect(subject.add_message).to eq("OK")
    end

    context 'when user is nil' do
      let(:git_user) { nil }

      it 'handles anonymous clones' do
        expect(subject.add_message).to be_nil
      end
    end
  end

  describe '#message' do
    shared_examples 'errors per protocol' do
      shared_examples 'returns redirect message' do
        it do
          message = <<~MSG
            #{container_label} '#{redirect_path}' was moved to '#{repository.container.full_path}'.

            Please update your Git remote:

              git remote set-url origin #{url_to_repo}
          MSG

          expect(subject.message).to eq(message)
        end
      end

      context 'when protocol is http' do
        it_behaves_like 'returns redirect message' do
          let(:url_to_repo) { http_url_to_repo }
        end
      end

      context 'when protocol is ssh' do
        let(:protocol) { 'ssh' }

        it_behaves_like 'returns redirect message' do
          let(:url_to_repo) { ssh_url_to_repo }
        end
      end
    end

    context 'with project' do
      it_behaves_like 'errors per protocol' do
        let(:container_label) { 'Project' }
        let(:http_url_to_repo) { project.http_url_to_repo }
        let(:ssh_url_to_repo) { project.ssh_url_to_repo }
      end
    end

    context 'with wiki' do
      let(:repository) { project.wiki.repository }

      it_behaves_like 'errors per protocol' do
        let(:container_label) { 'Project wiki' }
        let(:http_url_to_repo) { project.wiki.http_url_to_repo }
        let(:ssh_url_to_repo) { project.wiki.ssh_url_to_repo }
      end
    end

    context 'with project snippet' do
      let_it_be(:snippet) { create(:project_snippet, :repository, project: project, author: user) }

      let(:repository) { snippet.repository }

      it_behaves_like 'errors per protocol' do
        let(:container_label) { 'Project snippet' }
        let(:http_url_to_repo) { snippet.http_url_to_repo }
        let(:ssh_url_to_repo) { snippet.ssh_url_to_repo }
      end
    end

    context 'with personal snippet' do
      let_it_be(:snippet) { create(:personal_snippet, :repository, author: user) }

      let(:repository) { snippet.repository }

      it_behaves_like 'errors per protocol' do
        let(:container_label) { 'Personal snippet' }
        let(:http_url_to_repo) { snippet.http_url_to_repo }
        let(:ssh_url_to_repo) { snippet.ssh_url_to_repo }
      end
    end
  end
end
