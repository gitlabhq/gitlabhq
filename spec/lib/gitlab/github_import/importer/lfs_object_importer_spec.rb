# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::LfsObjectImporter, feature_category: :importers do
  let(:project) { create(:project) }
  let(:headers) { { 'Authorization' => 'RemoteAuth 12345' } }
  let(:lfs_attributes) do
    {
      oid: 'oid',
      size: 1,
      link: 'http://www.gitlab.com/lfs_objects/oid',
      headers: headers
    }
  end

  let(:lfs_download_object) { LfsDownloadObject.new(**lfs_attributes) }
  let(:github_lfs_object) { Gitlab::GithubImport::Representation::LfsObject.new(lfs_attributes) }

  let(:importer) { described_class.new(github_lfs_object, project, nil) }

  describe '#execute' do
    let(:service) { instance_double(Projects::LfsPointers::LfsDownloadService) }

    before do
      allow(importer).to receive(:lfs_download_object).and_return(lfs_download_object)
      allow(Projects::LfsPointers::LfsDownloadService).to receive(:new)
        .with(project, lfs_download_object)
        .and_return(service)
    end

    context 'when download succeeds' do
      it 'calls the LfsDownloadService and returns the result' do
        result = { status: :success }

        expect(service).to receive(:execute).and_return(result)

        expect(importer.execute).to eq(result)
      end
    end

    context 'when download fails with rate limit error' do
      it 'raises RateLimitError when result contains 429 error code' do
        result = {
          status: :error,
          message: "LFS file with oid couldn't be downloaded from http://www.gitlab.com/lfs_objects/oid: Received error code 429"
        }

        expect(service).to receive(:execute).and_return(result)

        expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError) do |error|
          expect(error.message).to eq('Rate Limit exceeded')
          expect(error.reset_in).to eq(120)
        end
      end
    end

    context 'when download fails with other error' do
      it 'returns the error result' do
        result = { status: :error, message: 'Some other error' }

        expect(service).to receive(:execute).and_return(result)

        expect(importer.execute).to eq(result)
      end
    end
  end

  describe '#lfs_download_object' do
    it 'creates the download object with the correct attributes' do
      expect(importer.lfs_download_object).to have_attributes(lfs_attributes)
    end
  end
end
