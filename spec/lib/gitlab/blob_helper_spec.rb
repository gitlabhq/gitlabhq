# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BlobHelper do
  include FakeBlobHelpers

  let(:project) { create(:project) }
  let(:blob) { fake_blob(path: 'file.txt') }
  let(:bmp_blob) { fake_blob(path: 'file.bmp') }
  let(:webp_blob) { fake_blob(path: 'file.webp') }
  let(:large_blob) { fake_blob(path: 'test.pdf', size: 2.megabytes, binary: true) }

  describe '#extname' do
    it 'returns the extension' do
      expect(blob.extname).to eq('.txt')
    end
  end

  describe '#known_extension?' do
    it 'returns true' do
      expect(blob.known_extension?).to be_truthy
    end
  end

  describe '#viewable' do
    it 'returns true' do
      expect(blob.viewable?).to be_truthy
    end

    it 'returns false' do
      expect(large_blob.viewable?).to be_falsey
    end
  end

  describe '#large?' do
    it 'returns false' do
      expect(blob.large?).to be_falsey
    end

    it 'returns true' do
      expect(large_blob.large?).to be_truthy
    end
  end

  describe '#binary?' do
    it 'returns true' do
      expect(large_blob.binary?).to be_truthy
    end

    it 'returns false' do
      expect(blob.binary?).to be_falsey
    end
  end

  describe '#text?' do
    it 'returns true' do
      expect(blob.text_in_repo?).to be_truthy
    end

    it 'returns false' do
      expect(large_blob.text_in_repo?).to be_falsey
    end
  end

  describe '#image?' do
    context 'with a .txt file' do
      it 'returns false' do
        expect(blob.image?).to be_falsey
      end
    end

    context 'with a .bmp file' do
      it 'returns true' do
        expect(bmp_blob.image?).to be_truthy
      end
    end

    context 'with a .webp file' do
      it 'returns true' do
        expect(webp_blob.image?).to be_truthy
      end
    end
  end

  describe '#mime_type' do
    it 'returns text/plain' do
      expect(blob.mime_type).to eq('text/plain')
    end

    it 'returns application/pdf' do
      expect(large_blob.mime_type).to eq('application/pdf')
    end
  end

  describe '#binary_mime_type?' do
    it 'returns false' do
      expect(blob.binary_mime_type?).to be_falsey
    end
  end

  describe '#lines' do
    it 'returns the payload in an Array' do
      expect(blob.lines).to eq(['foo'])
    end
  end

  describe '#content_type' do
    it 'returns text/plain' do
      expect(blob.content_type).to eq('text/plain; charset=utf-8')
    end

    it 'returns text/plain' do
      expect(large_blob.content_type).to eq('application/pdf')
    end
  end

  describe '#encoded_newlines_re' do
    it 'returns a regular expression' do
      expect(blob.encoded_newlines_re).to eq(/\r\n|\r|\n/)
    end
  end

  describe '#ruby_encoding' do
    it 'returns UTF-8' do
      expect(blob.ruby_encoding).to eq('UTF-8')
    end
  end

  describe '#encoding' do
    it 'returns UTF-8' do
      expect(blob.ruby_encoding).to eq('UTF-8')
    end
  end

  describe '#empty?' do
    it 'returns false' do
      expect(blob.empty?).to be_falsey
    end
  end
end
