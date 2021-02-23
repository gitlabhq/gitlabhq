# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories do
  let(:progress) { StringIO.new }

  subject { described_class.new(progress) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:progress).and_return(progress)
    end
  end

  describe '#dump' do
    let_it_be(:projects) { create_list(:project, 5, :repository) }

    RSpec.shared_examples 'creates repository bundles' do
      specify :aggregate_failures do
        # Add data to the wiki, design repositories, and snippets, so they will be included in the dump.
        create(:wiki_page, container: project)
        create(:design, :with_file, issue: create(:issue, project: project))
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.owner)

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)

        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.wiki' + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.design' + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', personal_snippet.disk_path + '.bundle'))
        expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project_snippet.disk_path + '.bundle'))
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

        projects.each do |project|
          expect(subject).to receive(:dump_project).with(project).and_call_original
        end

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
      end

      describe 'command failure' do
        it 'dump_project raises an error' do
          allow(subject).to receive(:dump_project).and_raise(IOError)

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

          projects.each do |project|
            expect(subject).to receive(:dump_project).with(project).and_call_original
          end

          subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
        end

        it 'creates the expected number of threads with extra max concurrency' do
          expect(Thread).to receive(:new)
            .exactly(storage_keys.length * (max_storage_concurrency + 1)).times
            .and_call_original

          projects.each do |project|
            expect(subject).to receive(:dump_project).with(project).and_call_original
          end

          subject.dump(max_concurrency: 3, max_storage_concurrency: max_storage_concurrency)
        end

        describe 'command failure' do
          it 'dump_project raises an error' do
            allow(subject).to receive(:dump_project)
              .and_raise(IOError)

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

    let(:next_path_to_bundle) do
      [
        Rails.root.join('spec/fixtures/lib/backup/project_repo.bundle'),
        Rails.root.join('spec/fixtures/lib/backup/wiki_repo.bundle'),
        Rails.root.join('spec/fixtures/lib/backup/design_repo.bundle'),
        Rails.root.join('spec/fixtures/lib/backup/personal_snippet_repo.bundle'),
        Rails.root.join('spec/fixtures/lib/backup/project_snippet_repo.bundle')
      ].to_enum
    end

    it 'restores repositories from bundles', :aggregate_failures do
      allow_next_instance_of(described_class::BackupRestore) do |backup_restore|
        allow(backup_restore).to receive(:path_to_bundle).and_return(next_path_to_bundle.next)
      end

      subject.restore

      collect_commit_shas = -> (repo) { repo.commits('master', limit: 10).map(&:sha) }

      expect(collect_commit_shas.call(project.repository)).to eq(['393a7d860a5a4c3cc736d7eb00604e3472bb95ec'])
      expect(collect_commit_shas.call(project.wiki.repository)).to eq(['c74b9948d0088d703ee1fafeddd9ed9add2901ea'])
      expect(collect_commit_shas.call(project.design_repository)).to eq(['c3cd4d7bd73a51a0f22045c3a4c871c435dc959d'])
      expect(collect_commit_shas.call(personal_snippet.repository)).to eq(['3b3c067a3bc1d1b695b51e2be30c0f8cf698a06e'])
      expect(collect_commit_shas.call(project_snippet.repository)).to eq(['6e44ba56a4748be361a841e759c20e421a1651a1'])
    end

    describe 'command failure' do
      before do
        expect(Project).to receive(:find_each).and_yield(project)

        allow_next_instance_of(DesignManagement::Repository) do |repository|
          allow(repository).to receive(:create_repository) { raise 'Fail in tests' }
        end
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:create_repository) { raise 'Fail in tests' }
        end
      end

      context 'hashed storage' do
        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} (#{project.disk_path})")
        end
      end

      context 'legacy storage' do
        let_it_be(:project) { create(:project, :legacy_storage) }

        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} (#{project.disk_path})")
        end
      end
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

    it 'cleans existing repositories' do
      success_response = ServiceResponse.success(message: "Valid Snippet Repo")
      allow(Snippets::RepositoryValidationService).to receive_message_chain(:new, :execute).and_return(success_response)

      expect_next_instance_of(DesignManagement::Repository) do |repository|
        expect(repository).to receive(:remove)
      end

      # 4 times = project repo + wiki repo + project_snippet repo + personal_snippet repo
      expect(Repository).to receive(:new).exactly(4).times.and_wrap_original do |method, *original_args|
        full_path, container, kwargs = original_args

        repository = method.call(full_path, container, **kwargs)

        expect(repository).to receive(:remove)

        repository
      end

      subject.restore
    end

    context 'restoring snippets' do
      before do
        create(:snippet_repository, snippet: personal_snippet)
        create(:snippet_repository, snippet: project_snippet)

        allow_next_instance_of(described_class::BackupRestore) do |backup_restore|
          allow(backup_restore).to receive(:path_to_bundle).and_return(next_path_to_bundle.next)
        end
      end

      context 'when the repository is valid' do
        it 'restores the snippet repositories' do
          subject.restore

          expect(personal_snippet.snippet_repository.persisted?).to be true
          expect(personal_snippet.repository).to exist

          expect(project_snippet.snippet_repository.persisted?).to be true
          expect(project_snippet.repository).to exist
        end
      end

      context 'when repository is invalid' do
        before do
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
end
