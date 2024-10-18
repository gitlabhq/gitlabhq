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
end
