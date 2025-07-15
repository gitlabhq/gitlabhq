# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::NoteAttachmentsImporter, feature_category: :importers do
  subject(:importer) { described_class.new(note_text, project, client) }

  let_it_be(:project) { create(:project, import_source: 'nickname/public-test-repo') }

  let(:note_text) { Gitlab::GithubImport::Representation::NoteText.from_db_record(record) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:doc_url) { 'https://github.com/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt' }
  let(:image_url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ef2.jpeg' }
  let(:image_tag_url) { 'https://user-images.githubusercontent.com/6833842/0cf366b61ea5.jpeg' }
  let(:project_blob_url) { 'https://github.com/nickname/public-test-repo/blob/main/example.md' }
  let(:other_project_blob_url) { 'https://github.com/nickname/other-repo/blob/main/README.md' }
  let(:user_attachment_url) { 'https://github.com/user-attachments/assets/73433gh3' }
  let(:text) do
    <<-TEXT.split("\n").map(&:strip).join("\n")
      Some text...

      [special-doc](#{doc_url})
      ![image.jpeg](#{image_url})
      <img width=\"248\" alt=\"tag-image\" src="#{image_tag_url}">

      [link to project blob file](#{project_blob_url})
      [link to other project blob file](#{other_project_blob_url})

      <img width= \"200\" alt=\"user-attachment-image\" src="#{user_attachment_url}" \/>
    TEXT
  end

  shared_examples 'updates record description' do
    it 'changes attachment links' do
      importer.execute

      record.reload
      expect(record.description).to start_with("Some text...\n\n[special-doc](/uploads/")
      expect(record.description).to include('![image.jpeg](/uploads/')
      expect(record.description).to include('user-attachment-image')
    end

    it 'changes link to project blob files' do
      importer.execute

      record.reload
      expected_blob_link = "[link to project blob file](http://localhost/#{project.full_path}/-/blob/main/example.md)"
      expect(record.description).not_to include("[link to project blob file](#{project_blob_url})")
      expect(record.description).to include(expected_blob_link)
    end

    it "doesn't change links to other projects" do
      importer.execute

      record.reload
      expect(record.description).to include("[link to other project blob file](#{other_project_blob_url})")
    end

    context 'with new github image format' do
      let(:image_url) { 'https://github.com/nickname/public-test-repo/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11' }
      let(:image_tag_url) { 'https://github.com/nickname/public-test-repo/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11' }

      it 'changes image attachment links' do
        importer.execute

        record.reload
        expect(record.description).to include('![image.jpeg](/uploads/')
        expect(record.description).to include('<img width="248" alt="tag-image" src="/uploads')
      end
    end
  end

  describe '#execute' do
    let(:downloader_stub) { instance_double(Gitlab::GithubImport::AttachmentsDownloader) }
    let(:tmp_stub_doc) { Tempfile.create('attachment_download_test.txt') }
    let(:tmp_stub_image) { Tempfile.create('image.jpeg') }
    let(:tmp_stub_image_tag) { Tempfile.create('image-tag.jpeg') }
    let(:tmp_stub_user_attachment) { Tempfile.create('user-attachment.jpeg') }

    let(:access_token) { 'exampleGitHubToken' }
    let(:options) { { headers: { 'Authorization' => "Bearer #{access_token}" } } }

    before do
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(doc_url, options: options)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(image_url, options: options)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(image_tag_url, options: options)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(user_attachment_url, options: options)
        .and_return(downloader_stub)
      allow(downloader_stub).to receive(:perform).and_return(tmp_stub_doc, tmp_stub_image, tmp_stub_image_tag,
        tmp_stub_user_attachment)
      allow(downloader_stub).to receive(:delete).exactly(4).times
      allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
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

      it 'changes note text with new attachment urls' do
        importer.execute

        record.reload
        expect(record.note).to start_with("Some text...\n\n[special-doc](/uploads/")
        expect(record.note).to include('![image.jpeg](/uploads/')
        expect(record.note).to include('<img width="248" alt="tag-image" src="/uploads')
      end

      it 'changes note links to project blob files' do
        importer.execute

        record.reload
        expected_blob_link = "[link to project blob file](http://localhost/#{project.full_path}/-/blob/main/example.md)"
        expect(record.note).not_to include("[link to project blob file](#{project_blob_url})")
        expect(record.note).to include(expected_blob_link)
      end

      it "doesn't change note links to other projects" do
        importer.execute

        record.reload
        expect(record.note).to include("[link to other project blob file](#{other_project_blob_url})")
      end

      context 'when the attachment is video media' do
        let(:media_attachment_url) { 'https://github.com/user-attachments/assets/media-attachment' }
        let(:text) { media_attachment_url }
        let(:record) { create(:note, project: project, note: text) }
        let(:tmp_stub_media_attachment) { Tempfile.create('media-attachment.mp4') }
        let(:uploader_hash) do
          { alt: nil,
            url: '/uploads/test-secret/video.mp4',
            markdown: nil }
        end

        before do
          allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new).with(media_attachment_url,
            options: options)
            .and_return(downloader_stub)
          allow(downloader_stub).to receive(:perform).and_return(tmp_stub_media_attachment)

          allow_next_instance_of(FileUploader) do |uploader|
            allow(uploader).to receive(:to_h).and_return(uploader_hash)
          end

          allow(downloader_stub).to receive(:delete).once
          allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
        end

        it 'changes standalone attachment link to correct markdown' do
          importer.execute

          record.reload
          expect(record.note).to include("![media_attachment](/uploads/test-secret/video.mp4)")
        end
      end
    end
  end
end
