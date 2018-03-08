require 'spec_helper'

describe Gitlab::ImportExport::UploadsRestorer do
  describe 'bundle a project Git repo' do
    let(:export_path) { "#{Dir.tmpdir}/uploads_saver_spec" }
    let(:shared) { project.import_export_shared }

    before do
      allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
      FileUtils.mkdir_p(File.join(shared.export_path, 'uploads/random'))
      FileUtils.touch(File.join(shared.export_path, 'uploads/random', "dummy.txt"))
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    describe 'legacy storage' do
      let(:project) { create(:project, :legacy_storage) }

      subject(:restorer) { described_class.new(project: project, shared: shared) }

      it 'saves the uploads successfully' do
        expect(restorer.restore).to be true
      end

      it 'copies the uploads to the project path' do
        subject.restore

        uploads = Dir.glob(File.join(subject.uploads_path, '**/*')).map { |file| File.basename(file) }

        expect(uploads).to include('dummy.txt')
      end
    end

    describe 'hashed storage' do
      let(:project) { create(:project) }

      subject(:restorer) { described_class.new(project: project, shared: shared) }

      it 'saves the uploads successfully' do
        expect(restorer.restore).to be true
      end

      it 'copies the uploads to the project path' do
        subject.restore

        uploads = Dir.glob(File.join(subject.uploads_path, '**/*')).map { |file| File.basename(file) }

        expect(uploads).to include('dummy.txt')
      end
    end
  end
end
