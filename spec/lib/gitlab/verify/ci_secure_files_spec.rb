# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Verify::CiSecureFiles, factory_default: :keep, feature_category: :mobile_devops do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let_it_be(:objects) { create_list(:ci_secure_file, 3) }
  end

  describe '#run_batches' do
    let_it_be(:project) { create(:project) }
    let(:failures) { collect_failures }
    let(:failure) { failures[secure_file] }

    let!(:secure_file) { create(:ci_secure_file, project: project) }

    it 'passes secure_files with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails secure_files with a missing file' do
      FileUtils.rm_f(secure_file.file.path)

      expect(failures.keys).to contain_exactly(secure_file)
      expect(failure).to include('No such file or directory')
      expect(failure).to include(secure_file.file.path)
    end

    it 'fails secure_files with a mismatched checksum' do
      secure_file.update!(checksum: 'something incorrect')

      expect(failures.keys).to contain_exactly(secure_file)
      expect(failure).to include('Checksum mismatch')
    end

    context 'with remote files' do
      let(:file) { CarrierWaveStringFile.new }

      before do
        stub_ci_secure_file_object_storage
        secure_file.update!(file_store: ObjectStorage::Store::REMOTE)
      end

      describe 'returned hash object' do
        it 'passes secure_files in object storage that exist' do
          expect(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
          expect(file).to receive(:exists?).and_return(true)

          expect(failures).to eq({})
        end

        it 'fails secure_files in object storage that do not exist' do
          expect(CarrierWave::Storage::Fog::File).to receive(:new).and_return(file)
          expect(file).to receive(:exists?).and_return(false)

          expect(failures.keys).to contain_exactly(secure_file)
          expect(failure).to include('Remote object does not exist')
        end
      end
    end
  end
end
