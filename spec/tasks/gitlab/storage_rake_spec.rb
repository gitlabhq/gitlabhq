# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'rake gitlab:storage:*', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/storage'

    stub_warn_user_is_not_gitlab
  end

  shared_examples "rake listing entities" do |entity_name, storage_type|
    context 'limiting to 2' do
      before do
        stub_env('LIMIT' => 2)
      end

      it "lists 2 out of 3 #{storage_type.downcase} #{entity_name}" do
        create_collection

        expect { run_rake_task(task) }.to output(/Found 3 #{entity_name} using #{storage_type} Storage.*Displaying first 2 #{entity_name}/m).to_stdout
      end
    end

    context "without any #{storage_type.downcase} #{entity_name.singularize}" do
      it 'displays message for empty results' do
        expect { run_rake_task(task) }.to output(/Found 0 #{entity_name} using #{storage_type} Storage/).to_stdout
      end
    end
  end

  shared_examples "rake entities summary" do |entity_name, storage_type|
    context "with existing 3 #{storage_type.downcase} #{entity_name}" do
      it "reports 3 #{storage_type.downcase} #{entity_name}" do
        create_collection

        expect { run_rake_task(task) }.to output(/Found 3 #{entity_name} using #{storage_type} Storage/).to_stdout
      end
    end

    context "without any #{storage_type.downcase} #{entity_name.singularize}" do
      it 'displays message for empty results' do
        expect { run_rake_task(task) }.to output(/Found 0 #{entity_name} using #{storage_type} Storage/).to_stdout
      end
    end
  end

  shared_examples "make sure database is writable" do
    context 'read-only database' do
      it 'does nothing' do
        expect(Gitlab::Database).to receive(:read_only?).and_return(true)

        expect(Project).not_to receive(:with_unmigrated_storage)

        expect { run_rake_task(task) }.to abort_execution.with_message(/This task requires database write access. Exiting./)
      end
    end
  end

  shared_examples "handles custom BATCH env var" do |worker_klass|
    context 'in batches of 1' do
      before do
        stub_env('BATCH' => 1)
      end

      it "enqueues one #{worker_klass} per project" do
        projects.each do |project|
          expect(worker_klass).to receive(:perform_async).with(project.id, project.id)
        end

        run_rake_task(task)
      end
    end

    context 'in batches of 2' do
      before do
        stub_env('BATCH' => 2)
      end

      it "enqueues one #{worker_klass} per 2 projects" do
        projects.map(&:id).sort.each_slice(2) do |first, last|
          last ||= first
          expect(worker_klass).to receive(:perform_async).with(first, last)
        end

        run_rake_task(task)
      end
    end
  end

  shared_examples 'wait until database is ready' do
    it 'checks if the database is ready once' do
      expect(Gitlab::Database).to receive(:exists?).once

      run_rake_task(task)
    end

    context 'handles custom env vars' do
      before do
        stub_env('MAX_DATABASE_CONNECTION_CHECKS' => 3)
        stub_env('MAX_DATABASE_CONNECTION_INTERVAL' => 0.1)
      end

      it 'tries for 3 times, polling every 0.1 seconds' do
        expect(Gitlab::Database).to receive(:exists?).exactly(3).times.and_return(false)

        run_rake_task(task)
      end
    end
  end

  describe 'gitlab:storage:migrate_to_hashed' do
    let(:task) { 'gitlab:storage:migrate_to_hashed' }

    context 'with rollback already scheduled', :redis do
      it 'does nothing' do
        Sidekiq::Testing.disable! do
          ::HashedStorage::RollbackerWorker.perform_async(1, 5)

          expect(Project).not_to receive(:with_unmigrated_storage)

          expect { run_rake_task(task) }.to abort_execution.with_message(/There is already a rollback operation in progress/)
        end
      end
    end

    context 'with 0 legacy projects' do
      it 'does nothing' do
        expect(::HashedStorage::MigratorWorker).not_to receive(:perform_async)

        expect { run_rake_task(task) }.to abort_execution.with_message('There are no projects requiring storage migration. Nothing to do!')
      end
    end

    context 'with 3 legacy projects' do
      let(:projects) { create_list(:project, 3, :legacy_storage) }

      it 'enqueues migrations and count projects correctly' do
        projects.map(&:id).sort.tap do |ids|
          stub_env('ID_FROM', ids[0])
          stub_env('ID_TO', ids[1])
        end

        expect { run_rake_task(task) }.to output(/Enqueuing migration of 2 projects in batches/).to_stdout
      end

      it_behaves_like 'handles custom BATCH env var', ::HashedStorage::MigratorWorker
    end

    context 'with same id in range' do
      it 'displays message when project cant be found' do
        stub_env('ID_FROM', non_existing_record_id)
        stub_env('ID_TO', non_existing_record_id)

        expect { run_rake_task(task) }.to abort_execution.with_message(/There are no projects requiring storage migration with ID=#{non_existing_record_id}/)
      end

      it 'displays a message when project exists but its already migrated' do
        project = create(:project)
        stub_env('ID_FROM', project.id)
        stub_env('ID_TO', project.id)

        expect { run_rake_task(task) }.to abort_execution.with_message(/There are no projects requiring storage migration with ID=#{project.id}/)
      end

      it 'enqueues migration when project can be found' do
        project = create(:project, :legacy_storage)
        stub_env('ID_FROM', project.id)
        stub_env('ID_TO', project.id)

        expect { run_rake_task(task) }.to output(/Enqueueing storage migration .* \(ID=#{project.id}\)/).to_stdout
      end
    end
  end

  describe 'gitlab:storage:rollback_to_legacy' do
    let(:task) { 'gitlab:storage:rollback_to_legacy' }

    it_behaves_like 'make sure database is writable'

    context 'with migration already scheduled', :redis do
      it 'does nothing' do
        Sidekiq::Testing.disable! do
          ::HashedStorage::MigratorWorker.perform_async(1, 5)

          expect(Project).not_to receive(:with_unmigrated_storage)

          expect { run_rake_task(task) }.to abort_execution.with_message(/There is already a migration operation in progress/)
        end
      end
    end

    context 'with 0 hashed projects' do
      it 'does nothing' do
        expect(::HashedStorage::RollbackerWorker).not_to receive(:perform_async)

        expect { run_rake_task(task) }.to abort_execution.with_message('There are no projects that can have storage rolledback. Nothing to do!')
      end
    end

    context 'with 3 hashed projects' do
      let(:projects) { create_list(:project, 3) }

      it 'enqueues migrations and count projects correctly' do
        projects.map(&:id).sort.tap do |ids|
          stub_env('ID_FROM', ids[0])
          stub_env('ID_TO', ids[1])
        end

        expect { run_rake_task(task) }.to output(/Enqueuing rollback of 2 projects in batches/).to_stdout
      end

      it_behaves_like "handles custom BATCH env var", ::HashedStorage::RollbackerWorker
    end
  end

  describe 'gitlab:storage:legacy_projects' do
    it_behaves_like 'rake entities summary', 'projects', 'Legacy' do
      let(:task) { 'gitlab:storage:legacy_projects' }
      let(:create_collection) { create_list(:project, 3, :legacy_storage) }
    end

    it_behaves_like 'wait until database is ready' do
      let(:task) { 'gitlab:storage:legacy_projects' }
    end
  end

  describe 'gitlab:storage:list_legacy_projects' do
    it_behaves_like 'rake listing entities', 'projects', 'Legacy' do
      let(:task) { 'gitlab:storage:list_legacy_projects' }
      let(:create_collection) { create_list(:project, 3, :legacy_storage) }
    end
  end

  describe 'gitlab:storage:hashed_projects' do
    it_behaves_like 'rake entities summary', 'projects', 'Hashed' do
      let(:task) { 'gitlab:storage:hashed_projects' }
      let(:create_collection) { create_list(:project, 3, storage_version: 1) }
    end
  end

  describe 'gitlab:storage:list_hashed_projects' do
    it_behaves_like 'rake listing entities', 'projects', 'Hashed' do
      let(:task) { 'gitlab:storage:list_hashed_projects' }
      let(:create_collection) { create_list(:project, 3, storage_version: 1) }
    end
  end

  describe 'gitlab:storage:legacy_attachments' do
    it_behaves_like 'rake entities summary', 'attachments', 'Legacy' do
      let(:task) { 'gitlab:storage:legacy_attachments' }
      let(:project) { create(:project, storage_version: 1) }
      let(:create_collection) { create_list(:upload, 3, model: project) }
    end

    it_behaves_like 'wait until database is ready' do
      let(:task) { 'gitlab:storage:legacy_attachments' }
    end
  end

  describe 'gitlab:storage:list_legacy_attachments' do
    it_behaves_like 'rake listing entities', 'attachments', 'Legacy' do
      let(:task) { 'gitlab:storage:list_legacy_attachments' }
      let(:project) { create(:project, storage_version: 1) }
      let(:create_collection) { create_list(:upload, 3, model: project) }
    end
  end

  describe 'gitlab:storage:hashed_attachments' do
    it_behaves_like 'rake entities summary', 'attachments', 'Hashed' do
      let(:task) { 'gitlab:storage:hashed_attachments' }
      let(:project) { create(:project) }
      let(:create_collection) { create_list(:upload, 3, model: project) }
    end
  end

  describe 'gitlab:storage:list_hashed_attachments' do
    it_behaves_like 'rake listing entities', 'attachments', 'Hashed' do
      let(:task) { 'gitlab:storage:list_hashed_attachments' }
      let(:project) { create(:project) }
      let(:create_collection) { create_list(:upload, 3, model: project) }
    end
  end
end
