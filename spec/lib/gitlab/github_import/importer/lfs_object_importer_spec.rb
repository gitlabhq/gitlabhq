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
    it 'calls the LfsDownloadService with the lfs object attributes' do
      allow(importer).to receive(:lfs_download_object).and_return(lfs_download_object)

      service = double
      expect(Projects::LfsPointers::LfsDownloadService).to receive(:new).with(project, lfs_download_object).and_return(service)
      expect(service).to receive(:execute)

      importer.execute
    end
  end

  describe '#lfs_download_object' do
    it 'creates the download object with the correct attributes' do
      expect(importer.lfs_download_object).to have_attributes(lfs_attributes)
    end
  end
end
