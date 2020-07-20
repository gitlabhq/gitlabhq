# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Verify::LfsObjects do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let!(:objects) { create_list(:lfs_object, 3, :with_file) }
  end

  describe '#run_batches' do
    let(:failures) { collect_failures }
    let(:failure) { failures[lfs_object] }

    let!(:lfs_object) { create(:lfs_object, :with_file, :correct_oid) }

    it 'passes LFS objects with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails LFS objects with a missing file' do
      FileUtils.rm_f(lfs_object.file.path)

      expect(failures.keys).to contain_exactly(lfs_object)
      expect(failure).to include('No such file or directory')
      expect(failure).to include(lfs_object.file.path)
    end

    it 'fails LFS objects with a mismatched oid' do
      File.truncate(lfs_object.file.path, 0)

      expect(failures.keys).to contain_exactly(lfs_object)
      expect(failure).to include('Checksum mismatch')
    end

    context 'with remote files' do
      let(:file) { double(:file) }

      before do
        stub_lfs_object_storage
        lfs_object.update!(file_store: ObjectStorage::Store::REMOTE)
        expect(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
      end

      it 'passes LFS objects in object storage that exist' do
        expect(file).to receive(:exists?).and_return(true)

        expect(failures).to eq({})
      end

      it 'fails LFS objects in object storage that do not exist' do
        expect(file).to receive(:exists?).and_return(false)

        expect(failures.keys).to contain_exactly(lfs_object)
        expect(failure).to include('Remote object does not exist')
      end
    end
  end
end
