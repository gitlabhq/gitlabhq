require 'rails_helper'

describe Blob do
  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '#svg?' do
    it 'is falsey when not text' do
      git_blob = double(text?: false)

      expect(described_class.decorate(git_blob)).not_to be_svg
    end

    it 'is falsey when no language is detected' do
      git_blob = double(text?: true, language: nil)

      expect(described_class.decorate(git_blob)).not_to be_svg
    end

    it' is falsey when language is not SVG' do
      git_blob = double(text?: true, language: double(name: 'XML'))

      expect(described_class.decorate(git_blob)).not_to be_svg
    end

    it 'is truthy when language is SVG' do
      git_blob = double(text?: true, language: double(name: 'SVG'))

      expect(described_class.decorate(git_blob)).to be_svg
    end
  end

  describe '#to_partial_path' do
    def stubbed_blob(overrides = {})
      overrides.reverse_merge!(
        image?: false,
        language: nil,
        lfs_pointer?: false,
        svg?: false,
        text?: false
      )

      described_class.decorate(double).tap do |blob|
        allow(blob).to receive_messages(overrides)
      end
    end

    it 'handles LFS pointers' do
      blob = stubbed_blob(lfs_pointer?: true)

      expect(blob.to_partial_path).to eq 'download'
    end

    it 'handles SVGs' do
      blob = stubbed_blob(text?: true, svg?: true)

      expect(blob.to_partial_path).to eq 'image'
    end

    it 'handles images' do
      blob = stubbed_blob(image?: true)

      expect(blob.to_partial_path).to eq 'image'
    end

    it 'handles text' do
      blob = stubbed_blob(text?: true)

      expect(blob.to_partial_path).to eq 'text'
    end

    it 'defaults to download' do
      blob = stubbed_blob

      expect(blob.to_partial_path).to eq 'download'
    end
  end
end
