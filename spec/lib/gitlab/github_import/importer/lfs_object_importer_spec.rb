require 'spec_helper'

describe Gitlab::GithubImport::Importer::LfsObjectImporter do
  let(:project) { create(:project) }
  let(:download_link) { "http://www.gitlab.com/lfs_objects/oid" }

  let(:github_lfs_object) do
    Gitlab::GithubImport::Representation::LfsObject.new(
      oid: 'oid', download_link: download_link
    )
  end

  let(:importer) { described_class.new(github_lfs_object, project, nil) }

  describe '#execute' do
    it 'calls the LfsDownloadService with the lfs object attributes' do
      expect_any_instance_of(Projects::LfsPointers::LfsDownloadService)
        .to receive(:execute).with('oid', download_link)

      importer.execute
    end
  end
end
