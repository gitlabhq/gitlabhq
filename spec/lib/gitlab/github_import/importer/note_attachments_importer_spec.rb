# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::NoteAttachmentsImporter, feature_category: :importers do
  subject(:importer) { described_class.new(note_text, project, client) }

  let_it_be(:project) { create(:project, import_source: 'nickname/public-test-repo') }

  let(:note_text) { Gitlab::GithubImport::Representation::NoteText.from_db_record(record) }
  let(:web_endpoint) { 'https://github.com' }
  let(:client) do
    instance_double(Gitlab::GithubImport::Client).tap do |double|
      allow(double).to receive(:web_endpoint).and_return(web_endpoint)
    end
  end

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
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
        .with(doc_url, options: options, web_endpoint: web_endpoint)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
        .with(image_url, options: options, web_endpoint: web_endpoint)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
        .with(image_tag_url, options: options, web_endpoint: web_endpoint)
        .and_return(downloader_stub)
      allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
        .with(user_attachment_url, options: options, web_endpoint: web_endpoint)
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

      context 'when the attachment is supported video media' do
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
            options: options, web_endpoint: web_endpoint)
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

      context 'with GHE domain' do
        let(:web_endpoint) { 'https://github.enterprise.com' }
        let(:client) { instance_double(Gitlab::GithubImport::Client, web_endpoint: web_endpoint) }
        let(:ghe_doc_url) { "#{web_endpoint}/nickname/public-test-repo/files/9020437/git-cheat-sheet.txt" }
        let(:ghe_image_url) { "#{web_endpoint}/user-attachments/assets/73433gh3" }

        let(:text) do
          <<-TEXT.split("\n").map(&:strip).join("\n")
            Some text...
            [ghe-doc](#{ghe_doc_url})
            ![ghe-image](#{ghe_image_url})
          TEXT
        end

        let(:record) { create(:release, project: project, description: text) }

        before do
          allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
            .with(ghe_doc_url, options: options, web_endpoint: web_endpoint)
            .and_return(downloader_stub)
          allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
            .with(ghe_image_url, options: options, web_endpoint: web_endpoint)
            .and_return(downloader_stub)
          allow(downloader_stub).to receive(:perform).and_return(tmp_stub_doc, tmp_stub_image, tmp_stub_image_tag,
            tmp_stub_user_attachment)
          allow(downloader_stub).to receive(:delete).twice
          allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
          allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
        end

        it 'changes attachment links' do
          importer.execute

          record.reload
          expect(record.description).to start_with("Some text...\n[ghe-doc](/uploads/")
          expect(record.description).to include("![ghe-image](/uploads/")
        end

        context 'when the attachment is file' do
          let(:pdf_file_url) { "#{web_endpoint}/user-attachments/files/3/pdf-attachment.pdf" }
          let(:zip_file_url) { "#{web_endpoint}/user-attachments/files/4/zip-attachment.zip" }

          let(:text) do
            <<-TEXT.split("\n").map(&:strip).join("\n")
              Some text...
              [pdf-file](#{pdf_file_url})
              [zip-file](#{zip_file_url})
            TEXT
          end

          let(:record) { create(:note, project: project, note: text) }

          before do
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(pdf_file_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(zip_file_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(downloader_stub).to receive(:perform).and_return(pdf_file_url, zip_file_url)
            allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
          end

          it 'does not change attachment link' do
            importer.execute

            record.reload
            expect(record.note).to include(pdf_file_url)
            expect(record.note).to include(zip_file_url)
          end
        end

        # rubocop:disable RSpec/MultipleMemoizedHelpers -- required
        context 'when the attachment is a mov file' do
          let(:ghe_video_url) { "#{web_endpoint}/user-attachments/assets/video-attachment" }
          let(:text) { ghe_video_url }
          let(:record) { create(:note, project: project, note: text) }
          let(:tmp_stub_video) { Tempfile.create('video-attachment') }
          let(:tmp_stub_path) { Pathname.new(tmp_stub_video.path) }
          let(:tmp_stub_video_with_ext) { Tempfile.create('video-attachment.mov') }
          let(:uploader_hash) do
            { alt: nil,
              url: '/uploads/test-secret/video.mov',
              markdown: nil }
          end

          before do
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(ghe_video_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(downloader_stub).to receive(:perform).and_return(tmp_stub_video)
            allow(downloader_stub).to receive(:delete)

            allow(Marcel::MimeType).to receive(:for).with(tmp_stub_path).and_return('video/quicktime')

            allow(File).to receive(:extname).and_call_original
            allow(File).to receive(:extname).with(tmp_stub_video.path).and_return('')

            mime_type_double = instance_double(Mime::Type)
            allow(Mime::Type).to receive(:lookup).with('video/quicktime').and_return(mime_type_double)
            allow(FileUtils).to receive(:mv).and_return(true)

            allow(File).to receive(:open).with(
              a_string_matching(/\.mov/), 'rb').and_return(tmp_stub_video_with_ext)

            allow(UploadService).to receive_message_chain(:new, :execute).and_return(uploader_hash)

            allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
            allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
          end

          it 'calls update_ghe_video_path for video files on GHE' do
            expect(importer).to receive(:update_ghe_video_path).with(tmp_stub_video).at_least(:once).and_call_original

            importer.execute
          end

          it 'changes standalone attachment link to correct markdown' do
            importer.execute
            record.reload
            expect(record.note).to include("![media_attachment](/uploads/test-secret/video.mov)")
          end
        end

        context 'when the attachment is a mp4 file' do
          let(:ghe_video_url) { "#{web_endpoint}/user-attachments/assets/video-attachment" }
          let(:text) { ghe_video_url }
          let(:record) { create(:note, project: project, note: text) }
          let(:tmp_stub_video) { Tempfile.create('video-attachment') }
          let(:tmp_stub_path) { Pathname.new(tmp_stub_video.path) }
          let(:tmp_stub_video_with_ext) { Tempfile.create('video-attachment.mp4') }
          let(:uploader_hash) do
            { alt: nil,
              url: '/uploads/test-secret/video.mp4',
              markdown: nil }
          end

          before do
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(ghe_video_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(downloader_stub).to receive(:perform).and_return(tmp_stub_video)
            allow(downloader_stub).to receive(:delete)

            allow(Marcel::MimeType).to receive(:for).with(tmp_stub_path).and_return('video/mp4')

            allow(File).to receive(:extname).and_call_original
            allow(File).to receive(:extname).with(tmp_stub_video.path).and_return('')

            mime_type_double = instance_double(Mime::Type)
            allow(Mime::Type).to receive(:lookup).with('video/mp4').and_return(mime_type_double)
            allow(FileUtils).to receive(:mv).and_return(true)

            allow(File).to receive(:open).with(
              a_string_matching(/\.mp4/), 'rb').and_return(tmp_stub_video_with_ext)

            allow(UploadService).to receive_message_chain(:new, :execute).and_return(uploader_hash)

            allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
            allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
          end

          it 'calls update_ghe_video_path for video files on GHE' do
            expect(importer).to receive(:update_ghe_video_path).with(tmp_stub_video).at_least(:once).and_call_original

            importer.execute
          end

          it 'changes standalone attachment link to correct markdown' do
            importer.execute
            record.reload
            expect(record.note).to include("![media_attachment](/uploads/test-secret/video.mp4)")
          end
        end

        context 'when the attachment is a webm file' do
          let(:ghe_video_url) { "#{web_endpoint}/user-attachments/assets/video-attachment" }
          let(:text) { ghe_video_url }
          let(:record) { create(:note, project: project, note: text) }
          let(:tmp_stub_video) { Tempfile.create('video-attachment') }
          let(:tmp_stub_path) { Pathname.new(tmp_stub_video.path) }
          let(:tmp_stub_video_with_ext) { Tempfile.create('video-attachment.webm') }
          let(:uploader_hash) do
            { alt: nil,
              url: '/uploads/test-secret/video.webm',
              markdown: nil }
          end

          before do
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(ghe_video_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(downloader_stub).to receive(:perform).and_return(tmp_stub_video)
            allow(downloader_stub).to receive(:delete)

            allow(Marcel::MimeType).to receive(:for).with(tmp_stub_path).and_return('video/webm')

            allow(File).to receive(:extname).and_call_original
            allow(File).to receive(:extname).with(tmp_stub_video.path).and_return('')

            mime_type_double = instance_double(Mime::Type)
            allow(Mime::Type).to receive(:lookup).with('video/webm').and_return(mime_type_double)
            allow(FileUtils).to receive(:mv).and_return(true)

            allow(File).to receive(:open).with(
              a_string_matching(/\.webm/), 'rb').and_return(tmp_stub_video_with_ext)

            allow(UploadService).to receive_message_chain(:new, :execute).and_return(uploader_hash)

            allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
            allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
          end

          it 'calls update_ghe_video_path for video files on GHE' do
            expect(importer).to receive(:update_ghe_video_path).with(tmp_stub_video).at_least(:once).and_call_original

            importer.execute
          end

          it 'changes standalone attachment link to correct markdown' do
            importer.execute
            record.reload
            expect(record.note).to include("![media_attachment](/uploads/test-secret/video.webm)")
          end
        end

        context 'when the attachment is an unsupported video format' do
          let(:ghe_video_url) { "#{web_endpoint}/user-attachments/assets/video-attachment" }
          let(:text) { ghe_video_url }
          let(:record) { create(:note, project: project, note: text) }
          let(:tmp_stub_video) { Tempfile.create('video-attachment') }
          let(:tmp_stub_path) { Pathname.new(tmp_stub_video.path) }
          let(:tmp_stub_video_with_ext) { Tempfile.create('video-attachment.avi') }
          let(:uploader_hash) do
            { alt: nil,
              url: '/uploads/test-secret/video.avi',
              markdown: nil }
          end

          before do
            allow(Gitlab::GithubImport::AttachmentsDownloader).to receive(:new)
              .with(ghe_video_url, options: options, web_endpoint: web_endpoint)
              .and_return(downloader_stub)
            allow(downloader_stub).to receive(:perform).and_return(tmp_stub_video)
            allow(downloader_stub).to receive(:delete)

            allow(Marcel::MimeType).to receive(:for).with(tmp_stub_path).and_return('video/avi')

            allow(File).to receive(:extname).and_call_original
            allow(File).to receive(:extname).with(tmp_stub_video.path).and_return('')

            mime_type_double = instance_double(Mime::Type)
            allow(Mime::Type).to receive(:lookup).with('video/avi').and_return(mime_type_double)
            allow(FileUtils).to receive(:mv).and_return(true)

            allow(File).to receive(:open).with(
              a_string_matching(/\.avi/), 'rb').and_return(tmp_stub_video_with_ext)

            allow(UploadService).to receive_message_chain(:new, :execute).and_return(uploader_hash)

            allow(client).to receive_message_chain(:octokit, :access_token).and_return(access_token)
            allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(nil)
          end

          it 'calls update_ghe_video_path for video files on GHE' do
            expect(importer).to receive(:update_ghe_video_path).with(tmp_stub_video).at_least(:once).and_call_original

            importer.execute
          end

          it 'does not update the link with a file extension' do
            importer.execute
            record.reload
            expect(record.note).to include("/uploads/test-secret/video")
          end
        end
        # rubocop:enable RSpec/MultipleMemoizedHelpers
      end

      context 'when rate limit error is raised' do
        let(:record) { create(:note, project: project, note: text) }
        let(:rate_limit_error) { Gitlab::GithubImport::RateLimitError.new('Rate limit exceeded', 120) }

        let(:text) do
          <<-TEXT.split("\n").map(&:strip).join("\n")
            Some text...

            [special-doc](#{doc_url})
            ![image.jpeg](#{image_url})
            <img width=\"248\" alt=\"tag-image\" src="#{image_tag_url}">
            <img width=\"200\" alt=\"user-attachment-image\" src="#{user_attachment_url}" \/>
          TEXT
        end

        context 'when rate limit is hit on first attachment' do
          before do
            allow(downloader_stub).to receive(:perform).and_raise(rate_limit_error)
          end

          it 'leaves the note unchanged with original attachment URLs' do
            expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)

            record.reload
            expect(record.note).to eq(text)
          end
        end

        context 'when rate limit is hit on second attachment' do
          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then raise rate_limit_error
              when 3 then tmp_stub_image_tag
              else tmp_stub_user_attachment
              end
            end
          end

          it 'updates the note with partially processed text and re-raises the error' do
            expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)

            record.reload
            expect(record.note).to start_with("Some text...")
            expect(record.note).to include("[special-doc](/uploads/")
            expect(record.note).to include("![image.jpeg](#{image_url})")
            expect(record.note).to include('<img width="248" alt="tag-image" src="/uploads')
            expect(record.note).to include('<img width="200" alt="user-attachment-image" src="/uploads')
          end
        end

        context 'when rate limit is hit multiple times' do
          let(:first_error) { Gitlab::GithubImport::RateLimitError.new('First error', 60) }
          let(:second_error) { Gitlab::GithubImport::RateLimitError.new('Second error', 120) }

          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then raise first_error
              when 3 then raise second_error
              else tmp_stub_user_attachment
              end
            end
          end

          it 'stores only the first error and re-raises it' do
            expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError) do |error|
              expect(error.message).to eq('First error')
              expect(error.reset_in).to eq(60)
            end

            record.reload
            expect(record.note).to start_with("Some text...")
            expect(record.note).to include("[special-doc](/uploads/")
            expect(record.note).to include("![image.jpeg](#{image_url})")
            expect(record.note).to include("<img width=\"248\" alt=\"tag-image\" src=\"#{image_tag_url}\"")
            expect(record.note).to include('<img width="200" alt="user-attachment-image" src="/uploads')
          end

          context 'when rate limit is hit after some successful downloads' do
            subject(:importer) do
              note_text_with_type = Gitlab::GithubImport::Representation::NoteText.from_db_record(record)
              note_text_with_type.instance_variable_set(:@object_type, :note_attachment)
              described_class.new(note_text_with_type, project, client)
            end

            before do
              call_count = 0
              allow(downloader_stub).to receive(:perform) do
                call_count += 1
                case call_count
                when 1 then tmp_stub_doc
                when 2 then tmp_stub_image
                when 3 then raise rate_limit_error
                else tmp_stub_user_attachment
                end
              end
            end

            it 'increments counter for successfully processed attachments before re-raising error' do
              allow(Gitlab::GithubImport::ObjectCounter).to receive(:increment)

              expect(Gitlab::GithubImport::ObjectCounter)
                .to receive(:increment)
                .with(project, :note_attachment, :imported, value: 3)

              expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)
            end

            it 'updates the note with successful uploads before re-raising error' do
              expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)

              record.reload
              expect(record.note).to include("[special-doc](/uploads/")
              expect(record.note).to include("![image.jpeg](/uploads/")
              expect(record.note).to include("src=\"#{image_tag_url}\"") # Not processed yet
              expect(record.note).to include('<img width="200" alt="user-attachment-image" src="/uploads')
            end
          end
        end
      end

      context 'when NotRetriableError is raised' do
        let(:record) { create(:note, project: project, note: text) }
        let(:rate_limit_error) { Gitlab::GithubImport::RateLimitError.new('Rate limit exceeded', 120) }
        let(:not_retriable_error) do
          Gitlab::GithubImport::AttachmentsDownloader::NotRetriableError.new(
            "Error downloading file from #{doc_url}. Error code: 404"
          )
        end

        let(:text) do
          <<-TEXT.split("\n").map(&:strip).join("\n")
            Some text...

            [special-doc](#{doc_url})
            ![image.jpeg](#{image_url})
            <img width=\"248\" alt=\"tag-image\" src="#{image_tag_url}">
            <img width=\"200\" alt=\"user-attachment-image\" src="#{user_attachment_url}" \/>
          TEXT
        end

        context 'when all attachment downloads fail with NotRetriableError' do
          before do
            allow(downloader_stub).to receive(:perform).and_raise(not_retriable_error)
          end

          it 'creates an import failure record for each failed attachment' do
            expect { importer.execute }
              .to change { project.import_failures.count }.by(4) # One for each attachment
          end

          it 'records the failure details with exception class and message' do
            importer.execute

            failure = project.import_failures.last

            expect(failure.source).to eq('Gitlab::GithubImport::AttachmentsDownloader')
            expect(failure.exception_class).to eq('Gitlab::GithubImport::AttachmentsDownloader::NotRetriableError')
            expect(failure.exception_message).to include("Error downloading file")
            expect(failure.exception_message).to include("Error code: 404")
            expect(failure.correlation_id_value).to be_present
            expect(failure.retry_count).to be_nil
            expect(failure.external_identifiers).to include(note_text.github_identifiers.stringify_keys)
          end

          it 'leaves the note unchanged with original attachment URLs' do
            allow(Gitlab::Import::ImportFailureService).to receive(:track)

            importer.execute

            expect(record.note).to eq(text)
          end
        end

        context 'when some attachment downloads fail with NotRetriableError and others succeed' do
          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then raise not_retriable_error
              when 3 then tmp_stub_image_tag
              else tmp_stub_user_attachment
              end
            end
          end

          it 'creates an import failure record only for the failed attachment' do
            expect { importer.execute }
              .to change { project.import_failures.count }.by(1)
          end

          it 'updates the note with successful uploads and leaves failed URLs unchanged' do
            importer.execute

            record.reload
            expect(record.note).to start_with("Some text...")
            expect(record.note).to include("[special-doc](/uploads/")
            expect(record.note).to include("![image.jpeg](#{image_url})")
            expect(record.note).to include('<img width="248" alt="tag-image" src="/uploads')
            expect(record.note).to include('<img width="200" alt="user-attachment-image" src="/uploads')
          end
        end

        context 'when rate limit error and NotRetriableError occur with some successful downloads' do
          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then tmp_stub_user_attachment
              when 3 then raise rate_limit_error
              else raise not_retriable_error
              end
            end
          end

          it 'does not create import failures as they will be tracked on retry' do
            expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)
              .and not_change { project.import_failures.count }
          end

          it 'updates the note with successful uploads only' do
            allow(Gitlab::Import::ImportFailureService).to receive(:track)

            expect { importer.execute }.to raise_error(Gitlab::GithubImport::RateLimitError)

            record.reload
            expect(record.note).to include("[special-doc](/uploads/")
            expect(record.note).to include("![image.jpeg](/uploads/")
            expect(record.note).to include("<img width=\"248\" alt=\"tag-image\" src=\"#{image_tag_url}\">")
            expect(record.note).to include(
              "<img width=\"200\" alt=\"user-attachment-image\" src=\"#{user_attachment_url}\""
            )
          end
        end

        context 'when NotRetriableError occurs after some successful downloads' do
          subject(:importer) do
            note_text_with_type = Gitlab::GithubImport::Representation::NoteText.from_db_record(record)
            note_text_with_type.instance_variable_set(:@object_type, :note_attachment)
            described_class.new(note_text_with_type, project, client)
          end

          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then tmp_stub_image
              when 3 then raise not_retriable_error
              else tmp_stub_user_attachment
              end
            end
          end

          it 'increments counter for successfully processed attachments' do
            expect(Gitlab::GithubImport::ObjectCounter)
              .to receive(:increment)
              .with(project, :note_attachment, :imported, value: 3)

            importer.execute
          end

          it 'creates an import failure record only for the failed attachment' do
            expect { importer.execute }
              .to change { project.import_failures.count }.by(1)
          end

          it 'updates the note with successful uploads and leaves failed URLs unchanged' do
            importer.execute

            record.reload
            expect(record.note).to include("[special-doc](/uploads/")
            expect(record.note).to include("![image.jpeg](/uploads/")
            expect(record.note).to include("src=\"#{image_tag_url}\"") # this is the failure
            expect(record.note).to include('<img width="200" alt="user-attachment-image" src="/uploads')
          end
        end

        context 'when attachment URL appears multiple times in text' do
          subject(:importer) do
            note_text_with_type = Gitlab::GithubImport::Representation::NoteText.from_db_record(record)
            note_text_with_type.instance_variable_set(:@object_type, :note_attachment)
            described_class.new(note_text_with_type, project, client)
          end

          let(:text) do
            <<-TEXT.split("\n").map(&:strip).join("\n")
              First reference: [special-doc](#{doc_url})
              Second reference: [special-doc-again](#{doc_url})
              Image: ![image.jpeg](#{image_url})
              Failed: <img src="#{image_tag_url}">
            TEXT
          end

          let(:record) { create(:note, project: project, note: text) }

          before do
            call_count = 0
            allow(downloader_stub).to receive(:perform) do
              call_count += 1
              case call_count
              when 1 then tmp_stub_doc
              when 2 then tmp_stub_image
              when 3 then raise not_retriable_error # Fail on image_tag_url
              else tmp_stub_user_attachment
              end
            end
          end

          it 'increments counter for each text replacement of successful downloads' do
            expect(Gitlab::GithubImport::ObjectCounter)
              .to receive(:increment)
              .with(project, :note_attachment, :imported, value: 2)

            importer.execute
          end

          it 'replaces all occurrences of successfully downloaded URLs' do
            importer.execute

            record.reload
            # doc_url appears twice - both should be replaced
            expect(record.note.scan(%r{\[special-doc\]\(/uploads/}).count).to eq(1)
            expect(record.note.scan(%r{\[special-doc-again\]\(/uploads/}).count).to eq(1)
            # image_url appears once - should be replaced
            expect(record.note.scan(%r{!\[image\.jpeg\]\(/uploads/}).count).to eq(1)
            # image_tag_url failed - should remain unchanged
            expect(record.note).to include("src=\"#{image_tag_url}\"")
          end
        end
      end
    end
  end

  describe '#external_identifiers' do
    context 'when record is an Issue' do
      let(:record) { create(:issue, project: project, description: text, iid: 42) }

      it 'returns correct identifiers for issue attachment' do
        identifiers = importer.send(:external_identifiers)

        expect(identifiers).to eq({
          "db_id" => record.id,
          "object_type" => "issue_attachment",
          "noteable_iid" => 42
        })
      end
    end

    context 'when record is a MergeRequest' do
      let(:record) { create(:merge_request, source_project: project, description: text, iid: 123) }

      it 'returns correct identifiers for merge request attachment' do
        identifiers = importer.send(:external_identifiers)

        expect(identifiers).to eq({
          "db_id" => record.id,
          "object_type" => "merge_request_attachment",
          "noteable_iid" => 123
        })
      end
    end

    context 'when record is a Note' do
      let(:issue) { create(:issue, project: project) }
      let(:record) { create(:note, project: project, noteable: issue, note: text) }

      it 'returns correct identifiers for note attachment' do
        identifiers = importer.send(:external_identifiers)

        expect(identifiers).to eq({
          "db_id" => record.id,
          "object_type" => "note_attachment",
          "noteable_type" => "Issue"
        })
      end
    end

    context 'when record is a Release' do
      let(:release) { create(:release, project: project, tag: 'v1.0.0', description: text) }
      let(:note_text) do
        Gitlab::GithubImport::Representation::NoteText.new(
          record_db_id: release.id,
          record_type: 'Release',
          text: text,
          tag: release.tag
        )
      end

      let(:importer) { described_class.new(note_text, project, client) }

      it 'returns correct identifiers for release attachment' do
        identifiers = importer.send(:external_identifiers)

        expect(identifiers).to eq({
          "db_id" => release.id,
          "object_type" => "release_attachment",
          "tag" => release.tag
        })
      end
    end

    context 'when record is an unsupported type' do
      let(:record) { create(:issue, project: project, description: text) }
      let(:note_text) do
        Gitlab::GithubImport::Representation::NoteText.new(
          record_db_id: record.id,
          record_type: 'UnsupportedModel',
          text: text
        )
      end

      let(:importer) { described_class.new(note_text, project, client) }

      it 'returns nil' do
        expect(importer.send(:external_identifiers)).to be_nil
      end
    end
  end
end
