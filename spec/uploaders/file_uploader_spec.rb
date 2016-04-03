require "spec_helper"

# provides matchers like `have_dimensions`
# https://github.com/carrierwaveuploader/carrierwave#testing-with-carrierwave
# require "carrierwave/test/matchers"


describe FileUploader do
  # include CarrierWave::Test::Matchers

  let(:project){ create(:project) }

  let(:image_file){ File.new Rails.root.join("spec", "fixtures", "rails_sample.jpg") }
  let(:video_file){ File.new Rails.root.join("spec", "fixtures", "video_sample.mp4") }
  let(:text_file) { File.new Rails.root.join("spec", "fixtures", "doc_sample.txt") }

  before do
    FileUploader.enable_processing = false
    @uploader = FileUploader.new(project)
  end

  after do
    FileUploader.enable_processing = true
    @uploader.remove!
  end

  it "should detect an image based on file extension" do
    @uploader.store!(image_file)
    expect(@uploader.image_or_video?).to be true
  end

  it "should detect a video based on file extension" do
    @uploader.store!(video_file)
    expect(@uploader.image_or_video?).to be true
  end

  it "should not return image_or_video? for other types" do
    @uploader.store!(text_file)
    expect(@uploader.image_or_video?).to be false
  end

end
