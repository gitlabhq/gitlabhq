# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportExportUploader do
  let(:model) { build_stubbed(:import_export_upload) }
  let(:upload) { create(:upload, model: model) }
  let(:import_export_upload) { build(:import_export_upload) }

  subject { described_class.new(model, :import_file) }

  context 'local store' do
    describe '#move_to_cache' do
      it 'returns false' do
        expect(subject.move_to_cache).to be false
      end

      context 'with project export' do
        subject { described_class.new(model, :export_file) }

        it 'returns true' do
          expect(subject.move_to_cache).to be true
        end
      end
    end

    describe '#move_to_store' do
      it 'returns true' do
        expect(subject.move_to_store).to be true
      end
    end
  end

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    patterns = {
      store_dir: %r{import_export_upload/import_file/},
      upload_path: %r{import_export_upload/import_file/}
    }

    it_behaves_like 'builds correct paths', patterns do
      let(:fixture) { File.join('spec', 'fixtures', 'group_export.tar.gz') }
    end

    describe '#move_to_cache' do
      it 'returns false' do
        expect(subject.move_to_cache).to be false
      end

      context 'with project export' do
        subject { described_class.new(model, :export_file) }

        it 'returns true' do
          expect(subject.move_to_cache).to be false
        end
      end
    end

    describe '#move_to_store' do
      it 'returns false' do
        expect(subject.move_to_store).to be false
      end
    end

    describe 'with an export file directly uploaded' do
      let(:tempfile) { Tempfile.new(['test', '.gz']) }

      before do
        stub_uploads_object_storage(described_class, direct_upload: true)
        import_export_upload.export_file = tempfile
      end

      it 'cleans up cached file' do
        cache_dir = File.join(import_export_upload.export_file.cache_path(nil), '*')

        import_export_upload.save!

        expect(Dir[cache_dir]).to be_empty
      end
    end
  end

  describe '.workhorse_local_upload_path' do
    it 'returns path that includes uploads dir' do
      expect(described_class.workhorse_local_upload_path).to end_with('/uploads/tmp/uploads')
    end
  end

  describe '#store_dirs', feature_category: :importers do
    let_it_be(:project) { create(:project) }
    let!(:export_job) { create(:project_export_job, project: project) }
    let!(:relation_export) { create(:project_relation_export, project_export_job: export_job) }
    let!(:relation_export_upload) do
      create(:relation_export_upload, relation_export: relation_export, project: project)
    end

    let!(:upload) { create(:upload, :import_export_uploader, model: relation_export_upload) }

    subject(:uploader) { upload.retrieve_uploader }

    context 'when RelationExportUpload and Upload are present' do
      it 'pulls the path details from the RelationExportUpload record' do
        expect(uploader.store_dirs).to eq({
          1 => "uploads/-/system/projects/import_export/relation_export_upload/export_file/#{upload.model.id}",
          2 => "projects/import_export/relation_export_upload/export_file/#{upload.model.id}"
        })
      end
    end

    context 'when RelationExportUpload is absent' do
      before do
        upload.model.delete
        upload.reload
      end

      it 'pulls the path details from the Upload record' do
        expect(uploader.model).to be_nil
        expect(uploader.store_dirs).to eq({
          1 => "uploads/-/system/projects/import_export/relation_export_upload/export_file/#{upload.model_id}",
          2 => "projects/import_export/relation_export_upload/export_file/#{upload.model_id}"
        })
      end

      context 'when Upload is missing mount point' do
        before do
          upload.update_column(:mount_point, nil)
          upload.reload
        end

        it 'raises an exception' do
          expect { upload.retrieve_uploader.store_dirs }
            .to raise_exception(StandardError, "Missing required upload attributes for path reconstruction")
        end
      end
    end
  end

  describe '#mounted_as', feature_category: :importers do
    let_it_be(:project) { create(:project) }
    let!(:export_job) { create(:project_export_job, project: project) }
    let!(:relation_export) { create(:project_relation_export, project_export_job: export_job) }
    let!(:relation_export_upload) do
      create(:relation_export_upload, relation_export: relation_export, project: project)
    end

    let!(:upload) { create(:upload, :import_export_uploader, model: relation_export_upload) }

    subject(:uploader) { upload.retrieve_uploader }

    context 'when RelationExportUpload and Upload are present' do
      it 'pulls the path details from the RelationExportUpload record' do
        expect(uploader.mounted_as).to eq(:export_file)
      end
    end

    context 'when RelationExportUpload is absent' do
      before do
        upload.model.delete
        upload.update_column :mount_point, 'other_mount_point'
        upload.reload
      end

      it 'pulls the path details from the Upload record' do
        expect(uploader.model).to be_nil
        expect(uploader.mounted_as).to eq(:other_mount_point)
      end
    end
  end
end
