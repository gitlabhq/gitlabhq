require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180627191935_cleanup_fill_file_store_background_migrations.rb')

describe CleanupFillFileStoreBackgroundMigrations, :migration, :sidekiq, :redis do
  shared_examples_for 'Draining sidekiq jobs' do
    context 'when there are unfinished background migrations' do
      it 'drains unfinished sidekiq jobs' do
        Sidekiq::Testing.disable! do
          BackgroundMigrationWorker
            .perform_in(2.minutes, migration_class, [1, 1])
          BackgroundMigrationWorker
            .perform_async(migration_class, [1, 1])

          migrate!

          expect(migration).to have_received(:perform).with(1, 1).twice
        end
      end
    end

    context 'when there are no unfinished background migrations' do
      it 'does nothing' do
        Sidekiq::Testing.disable! do
          migrate!

          expect(migration).not_to have_received(:perform)
        end
      end
    end
  end

  describe 'Job artifacts' do
    let(:migration) { spy('migration') }
    let(:migration_class) { 'FillFileStoreJobArtifact' }

    before do
      allow("Gitlab::BackgroundMigration::#{migration_class}".constantize)
        .to receive(:new).and_return(migration)
    end

    it_behaves_like 'Draining sidekiq jobs'

    context 'when there are still unmigrated job artifacts present' do
      let(:namespaces) { table('namespaces') }
      let(:projects) { table('projects') }
      let(:builds) { table('ci_builds') }
      let(:job_artifacts) { table('ci_job_artifacts') }

      before do
        namespace = namespaces.create(name: 'test-namespace', path: 'path')
        project = projects.create(name: 'test-project', namespace_id: namespace.id, path: 'path')
        build = builds.create(name: 'job1', ref: 'master', project_id: project.id)
  
        job_artifacts.create(id: 1, project_id: project.id, job_id: build.id, file_type: 1, file_store: nil)
        job_artifacts.create(id: 2, project_id: project.id, job_id: build.id, file_type: 2, file_store: nil)
      end

      it 'performs migrations synchronously' do
        expect(job_artifacts.all).to all(have_attributes(file_store: nil))

        migrate!

        expect(migration).to have_received(:perform).with(1, 2)
      end
    end
  end

  describe 'Lfs objects' do
    let(:migration) { spy('migration') }
    let(:migration_class) { 'FillFileStoreLfsObject' }

    before do
      allow("Gitlab::BackgroundMigration::#{migration_class}".constantize)
        .to receive(:new).and_return(migration)
    end

    it_behaves_like 'Draining sidekiq jobs'

    context 'when there are still unmigrated lfs objects present' do
      let(:lfs_objects) { table('lfs_objects') }

      before do
        lfs_objects.create(id: 3, oid: '123', size: 1, file_store: nil)
        lfs_objects.create(id: 4, oid: '125', size: 1, file_store: nil)
      end

      it 'performs migrations synchronously' do
        expect(lfs_objects.all).to all(have_attributes(file_store: nil))

        migrate!

        expect(migration).to have_received(:perform).with(3, 4)
      end
    end
  end

  describe 'Uploads' do
    let(:migration) { spy('migration') }
    let(:migration_class) { 'FillStoreUpload' }

    before do
      allow("Gitlab::BackgroundMigration::#{migration_class}".constantize)
        .to receive(:new).and_return(migration)
    end

    it_behaves_like 'Draining sidekiq jobs'

    context 'when there are still unmigrated lfs objects present' do
      let(:uploads) { table('uploads') }

      before do
        uploads.create(id: 1, size: 1, path: 'path', uploader: 'FileUploader', store: nil)
        uploads.create(id: 2, size: 1, path: 'path', uploader: 'FileUploader', store: nil)
      end

      it 'performs migrations synchronously' do
        expect(uploads.all).to all(have_attributes(store: nil))

        migrate!

        expect(migration).to have_received(:perform).with(1, 2)
      end
    end
  end
end
