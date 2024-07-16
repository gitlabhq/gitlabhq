# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Email::AttachmentUploader do
  describe "#execute" do
    let(:project) { create(:project) }
    let(:message_raw) { fixture_file("emails/attachment.eml") }
    let(:message) { Mail::Message.new(message_raw) }

    before do
      allow_next_instance_of(Gitlab::Sanitizers::Exif) do |instance|
        allow(instance).to receive(:clean_existing_path).and_call_original
      end
    end

    def expect_exif_sanitizer_and_upload_service_called
      expect(UploadService).to receive(:new)
                               .with(
                                 project,
                                 anything,
                                 FileUploader,
                                 uploaded_by_user_id: anything
                               )
                               .and_call_original

      expect_next_instance_of(Gitlab::Sanitizers::Exif) do |sanitizer|
        expect(sanitizer).to receive(:clean_existing_path) do |path, **options|
          expect(File.exist?(path)).to be true

          file = File.open(path, "rb")
          expect(options).to eql(content: file.read, skip_unallowed_types: true)
          file.close
        end
      end
    end

    it "uploads all attachments and returns their links" do
      expect_exif_sanitizer_and_upload_service_called

      links = described_class.new(message).execute(upload_parent: project, uploader_class: FileUploader)
      link = links.first

      expect(link).not_to be_nil
      expect(link[:alt]).to eq("bricks")
      expect(link[:url]).to include("bricks.png")
    end

    context 'with a signed message' do
      let(:message_raw) { fixture_file("emails/valid_reply_signed_smime.eml") }

      it 'uploads all attachments except the signature' do
        expect_exif_sanitizer_and_upload_service_called

        links = described_class.new(message).execute(upload_parent: project, uploader_class: FileUploader)

        expect(links).not_to include(a_hash_including(alt: 'smime.p7s'))

        image_link = links.first
        expect(image_link).not_to be_nil
        expect(image_link[:alt]).to eq('gitlab_logo')
        expect(image_link[:url]).to include('gitlab_logo.png')
      end
    end

    context 'with a signed message with mixed protocol prefix' do
      let(:message_raw) { fixture_file("emails/valid_reply_signed_smime_mixed_protocol_prefix.eml") }

      it 'uploads all attachments except the signature' do
        expect_exif_sanitizer_and_upload_service_called

        links = described_class.new(message).execute(upload_parent: project, uploader_class: FileUploader)

        expect(links).not_to include(a_hash_including(alt: 'smime.p7s'))

        image_link = links.first
        expect(image_link).not_to be_nil
        expect(image_link[:alt]).to eq('gitlab_logo')
        expect(image_link[:url]).to include('gitlab_logo.png')
      end
    end

    context 'with a message with no content type' do
      let(:message_raw) { fixture_file("emails/no_content_type.eml") }

      it 'uploads all attachments except the signature' do
        links = described_class.new(message).execute(upload_parent: project, uploader_class: FileUploader)

        expect(links).to eq([])
      end
    end
  end
end
