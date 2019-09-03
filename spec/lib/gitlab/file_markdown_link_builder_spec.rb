# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::FileMarkdownLinkBuilder do
  let(:custom_class) do
    Class.new do
      include Gitlab::FileMarkdownLinkBuilder
    end.new
  end

  before do
    allow(custom_class).to receive(:filename).and_return(filename)
  end

  describe 'markdown_link' do
    let(:url) { "/uploads/#{filename}"}

    before do
      allow(custom_class).to receive(:secure_url).and_return(url)
    end

    context 'when file name has the character ]' do
      let(:filename) { 'd]k.png' }

      it 'escapes the character' do
        expect(custom_class.markdown_link).to eq '![d\\]k](/uploads/d]k.png)'
      end
    end

    context 'when file is an image or video' do
      let(:filename) { 'dk.png' }

      it 'returns preview markdown link' do
        expect(custom_class.markdown_link).to eq '![dk](/uploads/dk.png)'
      end
    end

    context 'when file is not an image or video' do
      let(:filename) { 'dk.zip' }

      it 'returns markdown link' do
        expect(custom_class.markdown_link).to eq '[dk.zip](/uploads/dk.zip)'
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
    context 'when file is an image or video' do
      let(:filename) { 'dk.png' }

      it 'retrieves the name without the extension' do
        expect(custom_class.markdown_name).to eq 'dk'
      end
    end

    context 'when file is not an image or video' do
      let(:filename) { 'dk.zip' }

      it 'retrieves the name with the extesion' do
        expect(custom_class.markdown_name).to eq 'dk.zip'
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
