# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories do
  let(:progress) { spy(:stdout) }
  let(:parallel_enqueue) { true }
  let(:strategy) { spy(:strategy, parallel_enqueue?: parallel_enqueue) }

  subject { described_class.new(progress, strategy: strategy) }

  describe '#dump' do
    let_it_be(:projects) { create_list(:project, 5, :repository) }

    RSpec.shared_examples 'creates repository bundles' do
      it 'calls enqueue for each repository type', :aggregate_failures do
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.owner)

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)

        expect(strategy).to have_received(:start).with(:create)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:wait)
      end
    end

    context 'hashed storage' do
      let_it_be(:project) { create(:project, :repository) }

      it_behaves_like 'creates repository bundles'
    end

    context 'legacy storage' do
      let_it_be(:project) { create(:project, :repository, :legacy_storage) }

      it_behaves_like 'creates repository bundles'
    end

    context 'no concurrency' do
      it 'creates the expected number of threads' do
        expect(Thread).not_to receive(:new)

        expect(strategy).to receive(:start).with(:create)
        projects.each do |project|
          expect(strategy).to receive(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        end
        expect(strategy).to receive(:wait)

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
      end

      describe 'command failure' do
        it 'enqueue_project raises an error' do
          allow(strategy).to receive(:enqueue).with(anything, Gitlab::GlRepository::PROJECT).and_raise(IOError)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(IOError)
        end

        it 'project query raises an error' do
          allow(Project).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(ActiveRecord::StatementTimeout)
        end
      end

      it 'avoids N+1 database queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.count

        create_list(:project, 2, :repository)

        expect do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context 'concurrency with a strategy without parallel enqueueing support' do
      let(:parallel_enqueue) { false }

      it 'enqueues all projects sequentially' do
        expect(Thread).not_to receive(:new)

        expect(strategy).to receive(:start).with(:create)
        projects.each do |project|
          expect(strategy).to receive(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        end
        expect(strategy).to receive(:wait)

        subject.dump(max_concurrency: 2, max_storage_concurrency: 2)
      end
    end

    [4, 10].each do |max_storage_concurrency|
      context "max_storage_concurrency #{max_storage_concurrency}", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/241701' do
        let(:storage_keys) { %w[default test_second_storage] }

        before do
          allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(storage_keys)
        end

        it 'creates the expected number of threads' do
          expect(Thread).to receive(:new)
            .exactly(storage_keys.length * (max_storage_concurrency + 1)).times
            .and_call_original

          expect(strategy).to receive(:start).with(:create)
          projects.each do |project|
            expect(strategy).to receive(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          end
          expect(strategy).to receive(:wait)

          subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
        end

        it 'creates the expected number of threads with extra max concurrency' do
          expect(Thread).to receive(:new)
            .exactly(storage_keys.length * (max_storage_concurrency + 1)).times
            .and_call_original

          expect(strategy).to receive(:start).with(:create)
          projects.each do |project|
            expect(strategy).to receive(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          end
          expect(strategy).to receive(:wait)

          subject.dump(max_concurrency: 3, max_storage_concurrency: max_storage_concurrency)
        end

        describe 'command failure' do
          it 'enqueue_project raises an error' do
            allow(strategy).to receive(:enqueue).and_raise(IOError)

            expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(IOError)
          end

          it 'project query raises an error' do
            allow(Project).to receive_message_chain(:for_repository_storage, :includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

            expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(ActiveRecord::StatementTimeout)
          end

          context 'misconfigured storages' do
            let(:storage_keys) { %w[test_second_storage] }

            it 'raises an error' do
              expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(Backup::Error, 'repositories.storages in gitlab.yml is misconfigured')
            end
          end
        end

        it 'avoids N+1 database queries' do
          control_count = ActiveRecord::QueryRecorder.new do
            subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
          end.count

          create_list(:project, 2, :repository)

          expect do
            subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
          end.not_to exceed_query_limit(control_count)
        end
      end
    end
  end

  describe '#restore' do
    let_it_be(:project) { create(:project) }
    let_it_be(:personal_snippet) { create(:personal_snippet, author: project.owner) }
    let_it_be(:project_snippet) { create(:project_snippet, project: project, author: project.owner) }

    it 'calls enqueue for each repository type', :aggregate_failures do
      subject.restore

      expect(strategy).to have_received(:start).with(:restore)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::DESIGN)
      expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:wait)
    end

    context 'restoring object pools' do
      it 'schedules restoring of the pool', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, :failed)
        pool_repository.delete_object_pool

        subject.restore

        pool_repository.reload
        expect(pool_repository).not_to be_failed
        expect(pool_repository.object_pool.exists?).to be(true)
      end

      it 'skips pools with no source project, :sidekiq_might_not_need_inline' do
        pool_repository = create(:pool_repository, state: :obsolete)
        pool_repository.update_column(:source_project_id, nil)

        subject.restore

        pool_repository.reload
        expect(pool_repository).to be_obsolete
      end
    end

    context 'cleanup snippets' do
      before do
        create(:snippet_repository, snippet: personal_snippet)
        create(:snippet_repository, snippet: project_snippet)

        error_response = ServiceResponse.error(message: "Repository has more than one branch")
        allow(Snippets::RepositoryValidationService).to receive_message_chain(:new, :execute).and_return(error_response)
      end

      it 'shows the appropriate error' do
        subject.restore

        expect(progress).to have_received(:puts).with("Snippet #{personal_snippet.full_path} can't be restored: Repository has more than one branch")
        expect(progress).to have_received(:puts).with("Snippet #{project_snippet.full_path} can't be restored: Repository has more than one branch")
      end

      it 'removes the snippets from the DB' do
        expect { subject.restore }.to change(PersonalSnippet, :count).by(-1)
          .and change(ProjectSnippet, :count).by(-1)
          .and change(SnippetRepository, :count).by(-2)
      end

      it 'removes the repository from disk' do
        gitlab_shell = Gitlab::Shell.new
        shard_name = personal_snippet.repository.shard
        path = personal_snippet.disk_path + '.git'

        subject.restore

        expect(gitlab_shell.repository_exists?(shard_name, path)).to eq false
      end
    end
  end
end
