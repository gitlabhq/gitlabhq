# frozen_string_literal: true
require 'fast_spec_helper'

RSpec.describe Gitlab::FileMarkdownLinkBuilder do
  let(:custom_class) do
    Class.new do
      include Gitlab::FileMarkdownLinkBuilder
    end.new
  end

  before do
    allow(custom_class).to receive(:filename).and_return(filename)
  end

  describe 'markdown_link' do
    let(:url) { "/uploads/#{filename}" }

    before do
      allow(custom_class).to receive(:secure_url).and_return(url)
    end

    context 'when file name has the character ]' do
      let(:filename) { 'd]k.png' }

      it 'escapes the character' do
        expect(custom_class.markdown_link).to eq '![d\\]k](/uploads/d]k.png)'
      end
    end

    context 'when file is an image' do
      let(:filename) { 'my_image.png' }

      it 'returns preview markdown link' do
        expect(custom_class.markdown_link).to eq '![my_image](/uploads/my_image.png)'
      end
    end

    context 'when file is video' do
      let(:filename) { 'my_video.mp4' }

      it 'returns preview markdown link' do
        expect(custom_class.markdown_link).to eq '![my_video](/uploads/my_video.mp4)'
      end
    end

    context 'when file is audio' do
      let(:filename) { 'my_audio.wav' }

      it 'returns preview markdown link' do
        expect(custom_class.markdown_link).to eq '![my_audio](/uploads/my_audio.wav)'
      end
    end

    context 'when file is not embeddable' do
      let(:filename) { 'my_zip.zip' }

      it 'returns markdown link' do
        expect(custom_class.markdown_link).to eq '[my_zip.zip](/uploads/my_zip.zip)'
      end
    end

    context 'when file name is blank' do
      let(:filename) { nil }

      it 'returns nil' do
        expect(custom_class.markdown_link).to eq nil
      end
    end
  end

  describe 'mardown_name' do
    context 'when file is an image' do
      let(:filename) { 'my_image.png' }

      it 'retrieves the name without the extension' do
        expect(custom_class.markdown_name).to eq 'my_image'
      end
    end

    context 'when file is video' do
      let(:filename) { 'my_video.mp4' }

      it 'retrieves the name without the extension' do
        expect(custom_class.markdown_name).to eq 'my_video'
      end
    end

    context 'when file is audio' do
      let(:filename) { 'my_audio.wav' }

      it 'retrieves the name without the extension' do
        expect(custom_class.markdown_name).to eq 'my_audio'
      end
    end

    context 'when file is not embeddable' do
      let(:filename) { 'my_zip.zip' }

      it 'retrieves the name with the extesion' do
        expect(custom_class.markdown_name).to eq 'my_zip.zip'
      end
    end

    context 'when file name is blank' do
      let(:filename) { nil }

      it 'returns nil' do
        expect(custom_class.markdown_name).to eq nil
      end
    end
  end
end
