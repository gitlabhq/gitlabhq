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
          'key' => Base64.urlsafe_encode64('12345')
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
  let(:public_ip) { '18.245.0.1' }

  let_it_be(:project) { build(:project) }

  subject { uploader_class.new(object, :file) }

  context 'with CDN config' do
    before do
      stub_artifacts_object_storage(enabled: true)
      uploader_class.options = Settingslogic.new(Gitlab.config.uploads.deep_merge(cdn_options))
    end

    describe '#cdn_enabled_url' do
      it 'calls #cdn_signed_url' do
        expect(subject).not_to receive(:url)
        expect(subject).to receive(:cdn_signed_url).and_call_original

        result = subject.cdn_enabled_url(public_ip)

        expect(result.used_cdn).to be true
      end
    end

    describe '#use_cdn?' do
      it 'returns true' do
        expect(subject.use_cdn?(public_ip)).to be true
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
        expect(subject.use_cdn?(public_ip)).to be false
      end
    end
  end

  context 'with an unknown CDN provider' do
    before do
      cdn_options['object_store']['cdn']['provider'] = 'amazon'
      uploader_class.options = Settingslogic.new(Gitlab.config.uploads.deep_merge(cdn_options))
    end

    it 'raises an error' do
      expect { subject.use_cdn?(public_ip) }.to raise_error("Unknown CDN provider: amazon")
    end
  end
end
