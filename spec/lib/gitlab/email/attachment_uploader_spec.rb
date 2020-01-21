# frozen_string_literal: true

require "spec_helper"

describe Gitlab::Email::AttachmentUploader do
  describe "#execute" do
    let(:project) { create(:project) }
    let(:message_raw) { fixture_file("emails/attachment.eml") }
    let(:message) { Mail::Message.new(message_raw) }

    it "uploads all attachments and returns their links" do
      links = described_class.new(message).execute(upload_parent: project, uploader_class: FileUploader)
      link = links.first

      expect(link).not_to be_nil
      expect(link[:alt]).to eq("bricks")
      expect(link[:url]).to include("bricks.png")
    end
  end
end
