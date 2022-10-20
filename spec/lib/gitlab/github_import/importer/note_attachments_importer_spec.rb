# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::NoteAttachmentsImporter do
  subject(:importer) { described_class.new(note_text, project, client) }

  let_it_be(:project) { create(:project) }

  let(:note_text) { Gitlab::GithubImport::Representation::NoteText.from_db_record(record) }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  let(:doc_url) { 'https://github.com/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt' }
  let(:image_url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ef2.jpeg' }
  let(:image_tag_url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ea5.jpeg' }
  let(:text) do
    <<-TEXT.split("\n").map(&:strip).join("\n")
      Some text...

      [special-doc](#{doc_url})
      ![image.jpeg](#{image_url})
      <img width=\"248\" alt=\"tag-image\" src="#{image_tag_url}">
    TEXT
  end

  shared_examples 'updates record description' do
    it do
      importer.execute

      record.reload
      expect(record.description).to start_with("Some text...\n\n[special-doc](/uploads/")
      expect(record.description).to include('![image.jpeg](/uploads/')
      expect(record.description).to include('<img width="248" alt="tag-image" src="/uploads')
    end
  end

  describe '#execute' do
    let(:downloader_stub) { instance_double(Gitlab::GithubImport::AttachmentsDownloader) }
    let(:tmp_stub_doc) { Tempfile.create('attachment_download_test.txt') }
    let(:tmp_stub_image) { Tempfile.create('image.jpeg') }
    let(:tmp_stub_image_tag) { Tempfile.create('image-tag.jpeg') }

    before do
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(doc_url)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(image_url)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(image_tag_url)
        .and_return(downloader_stub)
      allow(downloader_stub).to receive(:perform).and_return(tmp_stub_doc, tmp_stub_image, tmp_stub_image_tag)
      allow(downloader_stub).to receive(:delete).exactly(3).times
    end

    context 'when importing release attachments' do
      let(:record) { create(:release, project: project, description: text) }

      it_behaves_like 'updates record description'
    end

    context 'when importing issue attachments' do
      let(:record) { create(:issue, project: project, description: text) }

      it_behaves_like 'updates record description'
    end

    context 'when importing merge request attachments' do
      let(:record) { create(:merge_request, source_project: project, description: text) }

      it_behaves_like 'updates record description'
    end

    context 'when importing note attachments' do
      let(:record) { create(:note, project: project, note: text) }

      it 'updates note text with new attachment urls' do
        importer.execute

        record.reload
        expect(record.note).to start_with("Some text...\n\n[special-doc](/uploads/")
        expect(record.note).to include('![image.jpeg](/uploads/')
        expect(record.note).to include('<img width="248" alt="tag-image" src="/uploads')
      end
    end
  end
end
