# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploaderHelper do
  let(:uploader) do
    example_uploader = Class.new(CarrierWave::Uploader::Base) do
      include UploaderHelper

      storage :file
    end

    example_uploader.new
  end

  describe '#extension_match?' do
    it 'returns false if file does not exist' do
      expect(uploader.file).to be_nil
      expect(uploader.send(:extension_match?, 'jpg')).to eq false
    end
  end
end
