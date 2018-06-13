require 'spec_helper'

describe Gitlab::Verify::Uploads do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let(:projects) { create_list(:project, 3, :with_avatar) }
    let!(:objects) { projects.flat_map(&:uploads) }
  end

  describe '#run_batches' do
    let(:project) { create(:project, :with_avatar) }
    let(:failures) { collect_failures }
    let(:failure) { failures[upload] }

    let!(:upload) { project.uploads.first }

    it 'passes uploads with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails uploads with a missing file' do
      FileUtils.rm_f(upload.absolute_path)

      expect(failures.keys).to contain_exactly(upload)
      expect(failure).to include('No such file or directory')
      expect(failure).to include(upload.absolute_path)
    end

    it 'fails uploads with a mismatched checksum' do
      upload.update!(checksum: 'something incorrect')

      expect(failures.keys).to contain_exactly(upload)
      expect(failure).to include('Checksum mismatch')
    end

    it 'fails uploads with a missing precalculated checksum' do
      upload.update!(checksum: '')

      expect(failures.keys).to contain_exactly(upload)
      expect(failure).to include('Checksum missing')
    end

    context 'with remote files' do
      let(:file) { double(:file) }

      before do
        stub_uploads_object_storage(AvatarUploader)
        upload.update!(store: ObjectStorage::Store::REMOTE)
        expect(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
      end

      it 'passes uploads in object storage that exist' do
        expect(file).to receive(:exists?).and_return(true)

        expect(failures).to eq({})
      end

      it 'fails uploads in object storage that do not exist' do
        expect(file).to receive(:exists?).and_return(false)

        expect(failures.keys).to contain_exactly(upload)
        expect(failure).to include('Remote object does not exist')
      end
    end
  end
end
