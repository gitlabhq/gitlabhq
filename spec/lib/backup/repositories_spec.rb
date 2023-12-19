# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories, feature_category: :backup_restore do
  let(:progress) { spy(:stdout) }
  let(:strategy) { spy(:strategy) }
  let(:storages) { [] }
  let(:paths) { [] }
  let(:skip_paths) { [] }
  let(:destination) { 'repositories' }
  let(:backup_id) { 'backup_id' }

  subject do
    described_class.new(
      progress,
      strategy: strategy,
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

        subject.dump(destination, backup_id)

        expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:finish!)
      end
    end

    context 'hashed storage' do
      let_it_be(:project) { create(:project_with_design, :repository) }

      it_behaves_like 'creates repository bundles'
    end

    context 'legacy storage' do
      let_it_be(:project) { create(:project_with_design, :repository, :legacy_storage) }

      it_behaves_like 'creates repository bundles'
    end

    describe 'command failure' do
      it 'enqueue_project raises an error' do
        allow(strategy).to receive(:enqueue).with(anything, Gitlab::GlRepository::PROJECT).and_raise(IOError)

        expect { subject.dump(destination, backup_id) }.to raise_error(IOError)
      end

      it 'project query raises an error' do
        allow(Project).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

        expect { subject.dump(destination, backup_id) }.to raise_error(ActiveRecord::StatementTimeout)
      end
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        subject.dump(destination, backup_id)
      end.count

      create_list(:project, 2, :repository)
      create_list(:snippet, 2, :repository)

      # Number of expected queries are 2 more than control_count
      # to account for the queries for project.design_management_repository
      # for each project.
      # We are using 2 projects here.
      expect do
        subject.dump(destination, backup_id)
      end.not_to exceed_query_limit(control_count + 2)
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

        subject.dump(destination, backup_id)

        expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:finish!)
      end
    end

    describe 'paths' do
      let_it_be(:project) { create(:project_with_design, :repository) }

      context 'project path' do
        let(:paths) { [project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'group path' do
        let(:paths) { [project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end

    describe 'skip_paths' do
      let_it_be(:project) { create(:project_with_design, :repository) }
      let_it_be(:excluded_project) { create(:project, :repository) }

      context 'project path' do
        let(:skip_paths) { [excluded_project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'group path' do
        let(:skip_paths) { [excluded_project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.dump(destination, backup_id)

          expect(strategy).to have_received(:start).with(:create, destination, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
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
      subject.restore(destination, backup_id)

      expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default], backup_id: backup_id)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
      expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
      expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
      expect(strategy).to have_received(:enqueue).with(project_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:enqueue).with(personal_snippet, Gitlab::GlRepository::SNIPPET)
      expect(strategy).to have_received(:finish!)
    end

    context 'restoring object pools' do
      it 'schedules restoring of the pool', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, :failed)
        pool_repository.delete_object_pool

        subject.restore(destination, backup_id)

        pool_repository.reload
        expect(pool_repository).not_to be_failed
        expect(pool_repository.object_pool.exists?).to be(true)
      end

      it 'skips pools when no source project is found', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, state: :obsolete)
        pool_repository.update_column(:source_project_id, nil)

        subject.restore(destination, backup_id)

        pool_repository.reload
        expect(pool_repository).to be_obsolete
      end
    end

    context 'storages' do
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

        subject.restore(destination, backup_id)

        expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default], backup_id: backup_id)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
        expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
        expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
        expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
        expect(strategy).to have_received(:finish!)
      end
    end

    context 'paths' do
      context 'project path' do
        let(:paths) { [project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: nil, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'group path' do
        let(:paths) { [project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project = create(:project, :repository)
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          excluded_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: nil, backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).not_to have_received(:enqueue).with(excluded_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end

    context 'skip_paths' do
      let_it_be(:excluded_project) { create(:project, :repository) }

      context 'project path' do
        let(:skip_paths) { [excluded_project.full_path] }

        it 'calls enqueue for all repositories on the specified project', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default], backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end

      context 'group path' do
        let(:skip_paths) { [excluded_project.namespace.full_path] }

        it 'calls enqueue for all repositories on all descendant projects', :aggregate_failures do
          excluded_project_snippet = create(:project_snippet, :repository, project: excluded_project)
          included_personal_snippet = create(:personal_snippet, :repository, author: excluded_project.first_owner)

          subject.restore(destination, backup_id)

          expect(strategy).to have_received(:start).with(:restore, destination, remove_all_repositories: %w[default], backup_id: backup_id)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project, Gitlab::GlRepository::PROJECT)
          expect(strategy).not_to have_received(:enqueue).with(excluded_project_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(included_personal_snippet, Gitlab::GlRepository::SNIPPET)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::PROJECT)
          expect(strategy).to have_received(:enqueue).with(project, Gitlab::GlRepository::WIKI)
          expect(strategy).to have_received(:enqueue).with(project.design_management_repository, Gitlab::GlRepository::DESIGN)
          expect(strategy).to have_received(:finish!)
        end
      end
    end
  end
end
