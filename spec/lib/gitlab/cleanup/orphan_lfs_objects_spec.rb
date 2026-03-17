# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanLfsObjects, feature_category: :source_code_management do
  let(:null_logger) { Logger.new('/dev/null') }

  subject(:service) { described_class.new(dry_run: dry_run, logger: null_logger) }

  before do
    allow(null_logger).to receive(:info)
    allow(null_logger).to receive(:warn)
  end

  shared_examples 'does not modify LFS data' do
    it 'does not delete LFS objects or links' do
      expect { service.run! }.to not_change { LfsObject.count }
        .and not_change { LfsObjectsProject.count }
    end
  end

  describe '#run!' do
    context 'with LFS objects that have missing files' do
      let_it_be(:project1) { create(:project) }
      let_it_be(:project2) { create(:project) }

      let!(:lfs_object_with_file) { create(:lfs_object, :with_file) }
      let!(:lfs_object_missing_file) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object_with_file)
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object_missing_file)
        create(:lfs_objects_project, project: project2, lfs_object: lfs_object_missing_file)

        FileUtils.rm_f(lfs_object_missing_file.file.path)
      end

      context 'when dry run is enabled (default)' do
        let(:dry_run) { true }

        it 'logs what would be deleted but does not modify data' do
          expect(null_logger).to receive(:info).with(/\[DRY RUN\].*Looking for LFS objects with missing files/)
          expect(null_logger).to receive(:info).with(/\[DRY RUN\].*Would remove LFS object/)

          expect { service.run! }.to not_change { LfsObject.count }
            .and not_change { LfsObjectsProject.count }
        end
      end

      context 'when dry run is disabled' do
        let(:dry_run) { false }

        it 'deletes LFS objects with missing files and their links', :aggregate_failures do
          expect { service.run! }.to change { LfsObject.count }.by(-1)
            .and change { LfsObjectsProject.count }.by(-2)

          expect(LfsObject.exists?(lfs_object_missing_file.id)).to be false
          expect(LfsObject.exists?(lfs_object_with_file.id)).to be true
        end

        it 'updates project statistics for all affected projects' do
          expect(ProjectCacheWorker).to receive(:perform_async).with(project1.id, [], %w[lfs_objects_size])
          expect(ProjectCacheWorker).to receive(:perform_async).with(project2.id, [], %w[lfs_objects_size])

          service.run!
        end
      end
    end

    context 'with no missing LFS objects' do
      let_it_be(:project1) { create(:project) }
      let(:dry_run) { false }

      let!(:lfs_object_with_file) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object_with_file)
      end

      it_behaves_like 'does not modify LFS data'
    end

    context 'when file check raises an error' do
      let(:dry_run) { true }

      let_it_be(:project1) { create(:project) }

      let!(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object)
      end

      it 'logs a warning and skips the object to avoid data loss' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(lfs_object.file.path).and_raise(StandardError, "Permission denied")

        expect(null_logger).to receive(:warn).with(/Error checking LFS object.*Permission denied.*Skipping/)
        expect(null_logger).not_to receive(:info).with(/Would remove LFS object/)

        service.run!
      end
    end

    context 'with object storage' do
      let(:dry_run) { true }

      let_it_be(:project1) { create(:project) }

      let!(:lfs_object_remote) { create(:lfs_object, :with_file) }

      before do
        stub_lfs_object_storage

        create(:lfs_objects_project, project: project1, lfs_object: lfs_object_remote)
        lfs_object_remote.update!(file_store: ObjectStorage::Store::REMOTE)

        file = instance_double(CarrierWave::Storage::Fog::File, exists?: false)
        allow(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
      end

      it 'detects missing files in object storage' do
        expect(null_logger).to receive(:info).with(/\[DRY RUN\].*Would remove LFS object/)
        service.run!
      end

      context 'when remote file object is nil' do
        let!(:lfs_object_nil_file) { create(:lfs_object, :with_file) }

        before do
          create(:lfs_objects_project, project: project1, lfs_object: lfs_object_nil_file)
          lfs_object_nil_file.update!(file_store: ObjectStorage::Store::REMOTE)
          # Stub file.file to return nil for remote store objects
          # rubocop:disable RSpec/AnyInstanceOf -- needed to stub objects yielded by find_each
          file_double = instance_double(LfsObjectUploader)
          allow(file_double).to receive(:file).and_return(nil)
          allow_any_instance_of(LfsObject).to receive(:file).and_return(file_double)
          # rubocop:enable RSpec/AnyInstanceOf
        end

        it 'treats the object as missing when file.file is nil' do
          expect(null_logger).to receive(:info).with(/Would remove LFS object/).twice
          service.run!
        end
      end

      context 'when remote file uploader is nil' do
        let!(:lfs_object_nil_uploader) { create(:lfs_object, :with_file) }

        before do
          create(:lfs_objects_project, project: project1, lfs_object: lfs_object_nil_uploader)
          lfs_object_nil_uploader.update!(file_store: ObjectStorage::Store::REMOTE)
          # rubocop:disable RSpec/AnyInstanceOf -- needed to stub objects yielded by find_each
          allow_any_instance_of(LfsObject).to receive(:file).and_return(nil)
          # rubocop:enable RSpec/AnyInstanceOf
        end

        it 'treats the object as missing when file is nil' do
          expect(null_logger).to receive(:info).with(/Would remove LFS object/).twice
          service.run!
        end
      end
    end

    context 'when local store file uploader is nil' do
      let(:dry_run) { true }
      let_it_be(:project1) { create(:project) }
      let!(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object)
        # Stub file to return nil to cover the &.path safe navigation branch
        # rubocop:disable RSpec/AnyInstanceOf -- needed to stub objects yielded by find_each
        allow_any_instance_of(LfsObject).to receive(:file).and_return(nil)
        # rubocop:enable RSpec/AnyInstanceOf
      end

      it 'treats the object as missing and logs it' do
        expect(null_logger).to receive(:info).with(/Would remove LFS object/)
        service.run!
      end
    end

    context 'when destroy fails with RecordNotDestroyed' do
      let(:dry_run) { false }
      let_it_be(:project1) { create(:project) }
      let!(:lfs_object_missing_file) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object_missing_file)
        FileUtils.rm_f(lfs_object_missing_file.file.path)

        allow_any_instance_of(LfsObject).to receive(:destroy!) # rubocop:disable RSpec/AnyInstanceOf -- needed to stub objects yielded by find_each
          .and_raise(ActiveRecord::RecordNotDestroyed.new("Cannot delete record"))
        allow(null_logger).to receive(:error)
      end

      it 'logs an error and continues processing' do
        expect(null_logger).to receive(:error)
          .with(/Failed to remove LFS object.*Cannot delete record/)

        # Should not raise, should continue
        expect { service.run! }.not_to raise_error
      end
    end
  end

  describe 'query performance' do
    let_it_be(:project1) { create(:project) }

    it 'does not cause N+1 queries when fetching linked project IDs', :request_store, :use_sql_query_cache do
      # Create initial object for control
      lfs_object = create(:lfs_object, :with_file)
      create(:lfs_objects_project, project: project1, lfs_object: lfs_object)
      FileUtils.rm_f(lfs_object.file.path)

      control = ActiveRecord::QueryRecorder.new do
        described_class.new(dry_run: true, logger: null_logger).run!
      end

      # Create additional objects
      4.times do
        obj = create(:lfs_object, :with_file)
        create(:lfs_objects_project, project: project1, lfs_object: obj)
        FileUtils.rm_f(obj.file.path)
      end

      expect do
        described_class.new(dry_run: true, logger: null_logger).run!
      end.to issue_same_number_of_queries_as(control).with_threshold(1)
    end
  end

  describe 'progress reporting' do
    let_it_be(:project1) { create(:project) }
    let(:dry_run) { true }

    it 'logs progress every PROGRESS_INTERVAL objects checked' do
      # Temporarily set PROGRESS_INTERVAL to 1 to test progress logging
      stub_const("#{described_class}::PROGRESS_INTERVAL", 1)

      2.times do
        lfs_object = create(:lfs_object, :with_file)
        create(:lfs_objects_project, project: project1, lfs_object: lfs_object)
        FileUtils.rm_f(lfs_object.file.path)
      end

      expect(null_logger).to receive(:info).with(/Looking for LFS objects/)
      expect(null_logger).to receive(:info).with(/Progress: checked 1 objects, found 0 missing so far/)
      expect(null_logger).to receive(:info).with(/Would remove LFS object/)
      expect(null_logger).to receive(:info).with(/Progress: checked 2 objects, found 1 missing so far/)
      expect(null_logger).to receive(:info).with(/Would remove LFS object/)
      expect(null_logger).to receive(:info).with(/Found 2 LFS object/)
      expect(null_logger).to receive(:info).with(/To actually remove/)

      service.run!
    end
  end
end
