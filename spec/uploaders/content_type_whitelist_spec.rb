# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContentTypeWhitelist do
  let_it_be(:model) { build_stubbed(:user) }

  let!(:uploader) do
    stub_const('DummyUploader', Class.new(CarrierWave::Uploader::Base))

    DummyUploader.class_eval do
      include ContentTypeWhitelist::Concern

      def content_type_whitelist
        %w[image/png image/jpeg]
      end
    end

    DummyUploader.new(model, :dummy)
  end

  context 'upload whitelisted file content type' do
    let(:path) { File.join('spec', 'fixtures', 'rails_sample.jpg') }

    it_behaves_like 'accepted carrierwave upload'
    it_behaves_like 'upload with content type', 'image/jpeg'
  end

  context 'upload non-whitelisted file content type' do
    let(:path) { File.join('spec', 'fixtures', 'sanitized.svg') }

    it_behaves_like 'denied carrierwave upload'
  end

  context 'upload misnamed non-whitelisted file content type' do
    let(:path) { File.join('spec', 'fixtures', 'not_a_png.png') }

    it_behaves_like 'denied carrierwave upload'
  end
end
