# encoding: utf-8
require 'rails_helper'

describe Blob do
  describe '.decorate' do
    it 'returns NilClass when given nil' do
      expect(described_class.decorate(nil)).to be_nil
    end
  end

  describe '#data' do
    context 'using a binary blob' do
      it 'returns the data as-is' do
        data = "\n\xFF\xB9\xC3"
        blob = described_class.new(double(binary?: true, data: data))

        expect(blob.data).to eq(data)
      end
    end

    context 'using a text blob' do
      it 'converts the data to UTF-8' do
        blob = described_class.new(double(binary?: false, data: "\n\xFF\xB9\xC3"))

        expect(blob.data).to eq("\n���")
      end
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

  describe '#pdf?' do
    it 'is falsey when file extension is not .pdf' do
      git_blob = Gitlab::Git::Blob.new(name: 'git_blob.txt')

      expect(described_class.decorate(git_blob)).not_to be_pdf
    end

    it 'is truthy when file extension is .pdf' do
      git_blob = Gitlab::Git::Blob.new(name: 'git_blob.pdf')

      expect(described_class.decorate(git_blob)).to be_pdf
    end
  end

  describe '#ipython_notebook?' do
    it 'is falsey when language is not Jupyter Notebook' do
      git_blob = double(text?: true, language: double(name: 'JSON'))

      expect(described_class.decorate(git_blob)).not_to be_ipython_notebook
    end

    it 'is truthy when language is Jupyter Notebook' do
      git_blob = double(text?: true, language: double(name: 'Jupyter Notebook'))

      expect(described_class.decorate(git_blob)).to be_ipython_notebook
    end
  end

  describe '#sketch?' do
    it 'is falsey with image extension' do
      git_blob = Gitlab::Git::Blob.new(name: "design.png")

      expect(described_class.decorate(git_blob)).not_to be_sketch
    end

    it 'is truthy with sketch extension' do
      git_blob = Gitlab::Git::Blob.new(name: "design.sketch")

      expect(described_class.decorate(git_blob)).to be_sketch
    end
  end

  describe '#video?' do
    it 'is falsey with image extension' do
      git_blob = Gitlab::Git::Blob.new(name: 'image.png')

      expect(described_class.decorate(git_blob)).not_to be_video
    end

    UploaderHelper::VIDEO_EXT.each do |ext|
      it "is truthy when extension is .#{ext}" do
        git_blob = Gitlab::Git::Blob.new(name: "video.#{ext}")

        expect(described_class.decorate(git_blob)).to be_video
      end
    end
  end

  describe '#stl?' do
    it 'is falsey with image extension' do
      git_blob = Gitlab::Git::Blob.new(name: 'file.png')

      expect(described_class.decorate(git_blob)).not_to be_stl
    end

    it 'is truthy with STL extension' do
      git_blob = Gitlab::Git::Blob.new(name: 'file.stl')

      expect(described_class.decorate(git_blob)).to be_stl
    end
  end

  describe '#to_partial_path' do
    let(:project) { double(lfs_enabled?: true) }

    def stubbed_blob(overrides = {})
      overrides.reverse_merge!(
        name: nil,
        image?: false,
        language: nil,
        lfs_pointer?: false,
        svg?: false,
        text?: false,
        binary?: false,
        stl?: false
      )

      described_class.decorate(Gitlab::Git::Blob.new({})).tap do |blob|
        allow(blob).to receive_messages(overrides)
      end
    end

    it 'handles LFS pointers with LFS enabled' do
      blob = stubbed_blob(lfs_pointer?: true, text?: true)
      expect(blob.to_partial_path(project)).to eq 'download'
    end

    it 'handles LFS pointers with LFS disabled' do
      blob = stubbed_blob(lfs_pointer?: true, text?: true)
      project = double(lfs_enabled?: false)
      expect(blob.to_partial_path(project)).to eq 'text'
    end

    it 'handles SVGs' do
      blob = stubbed_blob(text?: true, svg?: true)
      expect(blob.to_partial_path(project)).to eq 'svg'
    end

    it 'handles images' do
      blob = stubbed_blob(image?: true)
      expect(blob.to_partial_path(project)).to eq 'image'
    end

    it 'handles text' do
      blob = stubbed_blob(text?: true, name: 'test.txt')
      expect(blob.to_partial_path(project)).to eq 'text'
    end

    it 'defaults to download' do
      blob = stubbed_blob
      expect(blob.to_partial_path(project)).to eq 'download'
    end

    it 'handles PDFs' do
      blob = stubbed_blob(name: 'blob.pdf', pdf?: true)
      expect(blob.to_partial_path(project)).to eq 'pdf'
    end

    it 'handles iPython notebooks' do
      blob = stubbed_blob(text?: true, ipython_notebook?: true)
      expect(blob.to_partial_path(project)).to eq 'notebook'
    end

    it 'handles Sketch files' do
      blob = stubbed_blob(text?: true, sketch?: true, binary?: true)
      expect(blob.to_partial_path(project)).to eq 'sketch'
    end

    it 'handles STLs' do
      blob = stubbed_blob(text?: true, stl?: true)
      expect(blob.to_partial_path(project)).to eq 'stl'
    end
  end

  describe '#size_within_svg_limits?' do
    let(:blob) { described_class.decorate(double(:blob)) }

    it 'returns true when the blob size is smaller than the SVG limit' do
      expect(blob).to receive(:size).and_return(42)

      expect(blob.size_within_svg_limits?).to eq(true)
    end

    it 'returns true when the blob size is equal to the SVG limit' do
      expect(blob).to receive(:size).and_return(Blob::MAXIMUM_SVG_SIZE)

      expect(blob.size_within_svg_limits?).to eq(true)
    end

    it 'returns false when the blob size is larger than the SVG limit' do
      expect(blob).to receive(:size).and_return(1.terabyte)

      expect(blob.size_within_svg_limits?).to eq(false)
    end
  end
end
