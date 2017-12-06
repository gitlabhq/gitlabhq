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
      expect(uploader.favicon_main).to be_format('png')
    end

    it 'has the correct dimensions' do
      expect(uploader.favicon_main).to have_dimensions(32, 32)
    end
  end
end
