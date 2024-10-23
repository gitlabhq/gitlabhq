# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Targets::Repositories, feature_category: :backup_restore do
  let(:progress) { instance_double(StringIO, puts: nil, print: nil) }
  let(:strategy) { instance_double(Backup::GitalyBackup, start: nil, enqueue: nil, finish!: nil) }
  let(:storages) { [] }
  let(:paths) { [] }
  let(:skip_paths) { [] }
  let(:destination) { 'repositories' }
  let(:backup_id) { 'backup_id' }
  let(:backup_options) { Backup::Options.new }

  subject(:repositories) do
    described_class.new(
      progress,
      strategy: strategy,
      options: backup_options,
      storages: storages,
      paths: paths,
      skip_paths: skip_paths
    )
  end

  describe '#dump' do
    let_it_be(:projects) { create_list(:project_with_design, 5, :repository) }

    RSpec.shared_examples 'creates repository bundles' do
      it 'calls enqueue for each repository type', :aggregate_failures do
        project_snippet = create(:project_snippet, :repository, project: project)
        personal_snippet = create(:personal_snippet, :repository, author: project.first_owner)

        repositories.dump(destination, backup_id)

        expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
          Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:finish!)
      end
    end

    context 'with hashed storage' do
      let_it_be(:project) { create(:project_with_design, :repository) }

      it_behaves_like 'creates repository bundles'
    end

    context 'with legacy storage' do
      let_it_be(:project) { create(:project_with_design, :repository, :legacy_storage) }

      it_behaves_like 'creates repository bundles'
    end

    describe 'command failure' do
      it 'enqueue_project raises an error' do
        allow(strategy).to receive(:enqueue).with(anything, Gitlab::GlRepository::PROJECT).and_raise(IOError)

        expect { repositories.dump(destination, backup_id) }.to raise_error(IOError)
      end

      it 'project query raises an error' do
        allow(Project).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

        expect { repositories.dump(destination, backup_id) }.to raise_error(ActiveRecord::StatementTimeout)
      end
    end

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new do
        repositories.dump(destination, backup_id)
      end

      create_list(:project, 2, :repository)
      create_list(:personal_snippet, 2, :repository)

      # Number of expected queries are 2 more than control.count
      # to account for the queries for project.design_management_repository
      # for each project.
      # We are using 2 projects here.
      expect do
        repositories.dump(destination, backup_id)
      end.not_to exceed_query_limit(control).with_threshold(2)
    end

    describe 'storages' do
      let(:storages) { %w[default] }

      let_it_be(:project) { create(:project_with_design, :repository) }

      before do
        stub_storage_settings('test_second_storage' => {})
      end

      it 'calls enqueue for all repositories on the specified storage', :aggregate_failures do
        excluded_project = create(:project_with_design, :repository, repository_storage: 'test_second_storage')
        excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
        excluded_project_snippet.track_snippet_repository('test_second_storage')
        excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)
        excluded_personal_snippet.track_snippet_repository('test_second_storage')

        repositories.dump(destination, backup_id)

        expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
          Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:finish!)
      end
    end

    describe 'paths' do
      let_it_be(:project) { create(:project_with_design, :repository) }

      context 'with a project path' do
        let(:paths) { [project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'with a group path' do
        let(:paths) { [project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end

    describe 'skip_paths' do
      let_it_be(:project) { create(:project_with_design, :repository) }
      let_it_be(:excluded_project) { create(:project, :repository) }

      context 'with a project path' do
        let(:skip_paths) { [excluded_project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'with a group path' do
        let(:skip_paths) { [excluded_project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end
  end

  describe '#restore' do
    let_it_be(:project) { create(:project_with_design, :repository) }

    let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: project.first_owner) }
    let_it_be(:project_snippet) { create(:project_snippet, :repository, project: project, author: project.first_owner) }

    it 'calls enqueue for each repository type', :aggregate_failures do
      repositories.restore(destination, backup_id)

      expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default],
        backup_id: backup_id)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
      expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
        Gitlab::GlRepository::DESIGN)
      expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:finish!)
    end

    it 'logs an error if gitaly-backup exits with non-zero error code' do
      expect(strategy).to receive(:finish!).and_raise(::Backup::Error, 'gitaly-backup exit status 1')

      allow(repositories).to receive(:logger).and_return(Gitlab::BackupLogger)

      expect(Gitlab::BackupLogger).to receive(:error).with('gitaly-backup exit status 1')
      repositories.restore(destination, backup_id)
    end

    context 'when restoring object pools' do
      it 'schedules restoring of the pool', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, :failed)
        pool_repository.delete_object_pool

        repositories.restore(destination, backup_id)

        pool_repository.reload
        expect(pool_repository).not_to be_failed
        expect(pool_repository.object_pool.exists?).to be(true)
      end

      it 'skips pools when no source project is found', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, state: :obsolete)
        pool_repository.update_column(:source_project_id, nil)

        repositories.restore(destination, backup_id)

        pool_repository.reload
        expect(pool_repository).to be_obsolete
      end
    end

    context 'for storages' do
      let(:storages) { %w[default] }

      before do
        stub_storage_settings('test_second_storage' => {})
      end

      it 'calls enqueue for all repositories on the specified storage', :aggregate_failures do
        excluded_project = create(:project, :repository, repository_storage: 'test_second_storage')
        excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
        excluded_project_snippet.track_snippet_repository('test_second_storage')
        excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)
        excluded_personal_snippet.track_snippet_repository('test_second_storage')

        repositories.restore(destination, backup_id)

        expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default],
          backup_id: backup_id)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
          Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:finish!)
      end
    end

    context 'for paths' do
      context 'when project path' do
        let(:paths) { [project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: nil,
            backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'with a group path' do
        let(:paths) { [project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: nil,
            backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end

    context 'for skip_paths' do
      let_it_be(:excluded_project) { create(:project, :repository) }

      context 'with a project path' do
        let(:skip_paths) { [excluded_project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default],
            backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'with a group path' do
        let(:skip_paths) { [excluded_project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          repositories.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default],
            backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository,
            Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end
  end
end
