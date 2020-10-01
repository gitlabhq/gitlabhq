# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::ImageUploadPath do
  subject(:image_upload_path_entry) { described_class.new(config) }

  describe 'validations' do
    context 'with a valid config' do
      let(:config) { 'an-image-upload-path' }

      it { is_expected.to be_valid }

      describe '#value' do
        it 'returns a image_upload_path key' do
          expect(image_upload_path_entry.value).to eq config
        end
      end
    end

    context 'with an invalid config' do
      let(:config) { { not_a_string: true } }

      it { is_expected.not_to be_valid }

      it 'reports errors about wrong type' do
        expect(image_upload_path_entry.errors)
          .to include 'image upload path config should be a string'
      end
    end
  end

  describe '.default' do
    it 'returns default image_upload_path' do
      expect(described_class.default).to eq 'source/images'
    end
  end
end
