require 'spec_helper'

RSpec.describe FaviconUploader do
  include CarrierWave::Test::Matchers

  let(:uploader) { described_class.new(build_stubbed(:user)) }

  after do
    uploader.remove!
  end

  def upload_fixture(filename)
    fixture_file_upload(Rails.root.join('spec', 'fixtures', filename))
  end

  context 'versions' do
    before do
      uploader.store!(upload_fixture('dk.png'))
    end

    it 'has the correct format' do
      expect(uploader.default).to be_format('ico')
    end

    it 'has the correct dimensions' do
      expect(uploader.default).to have_dimensions(32, 32)
    end

    it 'generates all the status icons' do
      # make sure that the following each statement actually loops
      expect(FaviconUploader::STATUS_ICON_NAMES.count).to eq 10

      FaviconUploader::STATUS_ICON_NAMES.each do |status_name|
        expect(File.exist?(uploader.status_not_found.file.file)).to be true
      end
    end
  end
end
