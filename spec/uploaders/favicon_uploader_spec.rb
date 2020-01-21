# frozen_string_literal: true

require 'spec_helper'

describe FaviconUploader do
  let_it_be(:model) { build_stubbed(:user) }
  let_it_be(:uploader) { described_class.new(model, :favicon) }

  context 'upload type check' do
    FaviconUploader::EXTENSION_WHITELIST.each do |ext|
      context "#{ext} extension" do
        it_behaves_like 'type checked uploads', filenames: "image.#{ext}"
      end
    end
  end

  context 'upload non-whitelisted file extensions' do
    it 'will deny upload' do
      path = File.join('spec', 'fixtures', 'banana_sample.gif')
      fixture_file = fixture_file_upload(path)
      expect { uploader.cache!(fixture_file) }.to raise_exception(CarrierWave::IntegrityError)
    end
  end
end
