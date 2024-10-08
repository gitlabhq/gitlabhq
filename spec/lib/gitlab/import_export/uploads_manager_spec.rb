# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::UploadsManager do
  let(:shared) { project.import_export_shared }
  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:project) { create(:project) }
  let(:upload) { create(:upload, :issuable_upload, :object_storage, model: project) }
  let(:exported_file_path) { "#{shared.export_path}/uploads/#{upload.secret}/#{File.basename(upload.path)}" }

  subject(:manager) { described_class.new(project: project, shared: shared) }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end
    FileUtils.mkdir_p(shared.export_path)
  end

  after do
    FileUtils.rm_rf(shared.export_path)
  end

  describe '#save' do
    before do
      project.uploads << upload
    end

    context 'when the project has uploads locally stored' do
      let(:upload) { create(:upload, :issuable_upload, :with_file, model: project) }

      it 'does not cause errors' do
        manager.save # rubocop:disable Rails/SaveBang

        expect(shared.errors).to be_empty
      end

      it 'copies the file in the correct location when there is an upload' do
        manager.save # rubocop:disable Rails/SaveBang

        expect(File).to exist(exported_file_path)
      end

      context 'with orphaned project upload files' do
        let(:orphan_path) { File.join(FileUploader.absolute_base_dir(project), 'f93f088ddf492ffd950cf059002cbbb6', 'orphan.jpg') }
        let(:exported_orphan_path) { "#{shared.export_path}/uploads/f93f088ddf492ffd950cf059002cbbb6/orphan.jpg" }

        before do
          FileUtils.mkdir_p(File.dirname(orphan_path))
          FileUtils.touch(orphan_path)
        end

        after do
          FileUtils.rm_f(orphan_path)
        end

        it 'excludes orphaned upload files' do
          manager.save # rubocop:disable Rails/SaveBang

          expect(File).not_to exist(exported_orphan_path)
        end
      end

      context 'with an upload missing its file' do
        before do
          File.delete(upload.absolute_path)
        end

        it 'does not cause errors' do
          manager.save # rubocop:disable Rails/SaveBang

          expect(shared.errors).to be_empty
        end
      end
    end

    context 'when upload is in object storage' do
      before do
        stub_uploads_object_storage(FileUploader)
      end

      shared_examples 'export with invalid upload' do
        it 'ignores problematic upload and logs exception' do
          allow(manager).to receive(:download_or_copy_upload).and_raise(exception)
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(exception), project_id: project.id)

          manager.save # rubocop:disable Rails/SaveBang

          expect(shared.errors).to be_empty
          expect(File).not_to exist(exported_file_path)
        end
      end

      context 'when filename is too long' do
        let(:exception) { Errno::ENAMETOOLONG }

        include_examples 'export with invalid upload'
      end

      context 'when network exception occurs' do
        let(:exception) { Net::OpenTimeout }

        include_examples 'export with invalid upload'
      end
    end
  end

  describe '#restore' do
    before do
      stub_uploads_object_storage(FileUploader)

      FileUtils.mkdir_p(File.join(shared.export_path, 'uploads/72a497a02fe3ee09edae2ed06d390038'))
      FileUtils.touch(File.join(shared.export_path, 'uploads/72a497a02fe3ee09edae2ed06d390038', "dummy.txt"))
    end

    it 'restores the file' do
      manager.restore

      expect(project.uploads.map { |u| u.retrieve_uploader.filename }).to include('dummy.txt')
    end
  end
end
