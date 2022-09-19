# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ReleaseAttachmentsImporter do
  subject(:importer) { described_class.new(release_attachments, project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:release) { create(:release, project: project, description: description) }
  let(:release_attachments) do
    Gitlab::GithubImport::Representation::ReleaseAttachments
      .from_json_hash(release_db_id: release.id, description: release.description)
  end

  let(:doc_url) { 'https://github.com/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt' }
  let(:image_url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ef2.jpeg' }
  let(:description) do
    <<-TEXT.strip
      Some text...

      [special-doc](#{doc_url})
      ![image.jpeg](#{image_url})
    TEXT
  end

  describe '#execute' do
    let(:downloader_stub) { instance_double(Gitlab::GithubImport::AttachmentsDownloader) }
    let(:tmp_stub_doc) { Tempfile.create('attachment_download_test.txt') }
    let(:tmp_stub_image) { Tempfile.create('image.jpeg') }

    context 'when importing doc attachment' do
      before do
        allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(doc_url)
          .and_return(downloader_stub)
        allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(image_url)
          .and_return(downloader_stub)
        allow(downloader_stub).to receive(:perform).and_return(tmp_stub_doc, tmp_stub_image)
        allow(downloader_stub).to receive(:delete).twice

        allow(UploadService).to receive(:new)
          .with(project, tmp_stub_doc, FileUploader).and_call_original
        allow(UploadService).to receive(:new)
          .with(project, tmp_stub_image, FileUploader).and_call_original
      end

      it 'updates release description with new attachment url' do
        importer.execute

        release.reload
        expect(release.description).to start_with("Some text...\n\n      [special-doc](/uploads/")
        expect(release.description).to include('![image.jpeg](/uploads/')
      end
    end
  end
end
