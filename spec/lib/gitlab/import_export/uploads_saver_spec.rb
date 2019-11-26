# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::UploadsSaver do
  describe 'bundle a project Git repo' do
    let(:export_path) { "#{Dir.tmpdir}/uploads_saver_spec" }
    let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }
    let(:shared) { project.import_export_shared }

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    describe 'legacy storage' do
      let(:project) { create(:project, :legacy_storage) }

      subject(:saver) { described_class.new(shared: shared, project: project) }

      before do
        UploadService.new(project, file, FileUploader).execute
      end

      it 'saves the uploads successfully' do
        expect(saver.save).to be true
      end

      it 'copies the uploads to the export path' do
        saver.save

        uploads = Dir.glob(File.join(shared.export_path, 'uploads/**/*')).map { |file| File.basename(file) }

        expect(uploads).to include('banana_sample.gif')
      end
    end

    describe 'hashed storage' do
      let(:project) { create(:project) }

      subject(:saver) { described_class.new(shared: shared, project: project) }

      before do
        UploadService.new(project, file, FileUploader).execute
      end

      it 'saves the uploads successfully' do
        expect(saver.save).to be true
      end

      it 'copies the uploads to the export path' do
        saver.save

        uploads = Dir.glob(File.join(shared.export_path, 'uploads/**/*')).map { |file| File.basename(file) }

        expect(uploads).to include('banana_sample.gif')
      end
    end
  end
end
