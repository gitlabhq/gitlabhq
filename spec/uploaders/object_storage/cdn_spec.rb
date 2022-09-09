# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::CDN do
  let(:cdn_options) do
    {
      'object_store' => {
        'cdn' => {
          'provider' => 'google',
          'url' => 'https://gitlab.example.com',
          'key_name' => 'test-key',
          'key' => '12345'
        }
      }
    }.freeze
  end

  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern
      include ObjectStorage::CDN::Concern

      private

      # user/:id
      def dynamic_segment
        File.join(model.class.underscore, model.id.to_s)
      end
    end
  end

  let(:object) { build_stubbed(:user) }

  subject { uploader_class.new(object, :file) }

  context 'with CDN config' do
    before do
      uploader_class.options = Settingslogic.new(Gitlab.config.uploads.deep_merge(cdn_options))
    end

    describe '#use_cdn?' do
      it 'returns true' do
        expect_next_instance_of(ObjectStorage::CDN::GoogleCDN) do |cdn|
          expect(cdn).to receive(:use_cdn?).and_return(true)
        end

        expect(subject.use_cdn?('18.245.0.1')).to be true
      end
    end

    describe '#cdn_signed_url' do
      it 'returns a URL' do
        expect_next_instance_of(ObjectStorage::CDN::GoogleCDN) do |cdn|
          expect(cdn).to receive(:signed_url).and_return("https://cdn.example.com/path")
        end

        expect(subject.cdn_signed_url).to eq("https://cdn.example.com/path")
      end
    end
  end

  context 'without CDN config' do
    before do
      uploader_class.options = Gitlab.config.uploads
    end

    describe '#use_cdn?' do
      it 'returns false' do
        expect(subject.use_cdn?('18.245.0.1')).to be false
      end
    end
  end

  context 'with an unknown CDN provider' do
    before do
      cdn_options['object_store']['cdn']['provider'] = 'amazon'
      uploader_class.options = Settingslogic.new(Gitlab.config.uploads.deep_merge(cdn_options))
    end

    it 'raises an error' do
      expect { subject.use_cdn?('18.245.0.1') }.to raise_error("Unknown CDN provider: amazon")
    end
  end
end
