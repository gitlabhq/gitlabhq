require "spec_helper"

describe Gitlab::Email::AttachmentUploader do
  def fixture_file(filename)
    return '' if filename.blank?
    file_path = File.expand_path(Rails.root + 'spec/fixtures/' + filename)
    File.read(file_path)
  end

  describe "#execute" do
    let(:project) { build(:project) }
    let(:message_raw) { fixture_file("emails/attachment.eml") }
    let(:message) { Mail::Message.new(message_raw) }

    it "creates a post with an attachment" do
      links = described_class.new(message).execute(project)
      link = links.first

      expect(link).not_to be_nil
      expect(link[:is_image]).to be_truthy
      expect(link[:alt]).to eq("bricks")
      expect(link[:url]).to include("/#{project.path_with_namespace}")
      expect(link[:url]).to include("bricks.png")
    end
  end
end
