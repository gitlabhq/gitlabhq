# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Emoji do
  describe '.gl_emoji_tag' do
    it 'returns gl emoji tag if emoji is found' do
      emoji = TanukiEmoji.find_by_alpha_code('small_airplane')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to eq('<gl-emoji title="small airplane" data-name="airplane_small" data-unicode-version="7.0">🛩️</gl-emoji>')
    end

    it 'returns nil if emoji is not found' do
      emoji = TanukiEmoji.find_by_alpha_code('random')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to be_nil
    end
  end

  describe '.custom_emoji_tag' do
    let(:tag) { Nokogiri::HTML5.fragment(html).at_css('gl-emoji') }

    context 'without rendering the image' do
      let(:html) { described_class.custom_emoji_tag('tanuki', 'https://example.com/tanuki.png') }

      it 'leaves the element empty for the frontend to fill in', :aggregate_failures do
        expect(tag['title']).to eq('tanuki')
        expect(tag['data-name']).to eq('tanuki')
        expect(tag['data-fallback-src']).to eq('https://example.com/tanuki.png')
        expect(tag['data-unicode-version']).to eq('custom')
        expect(tag.children).to be_empty
      end
    end

    context 'when rendering the image' do
      let(:html) { described_class.custom_emoji_tag('tanuki', 'https://example.com/tanuki.png', render_image: true) }

      it 'nests an image with the emoji name as its text fallback', :aggregate_failures do
        img = tag.at_css('img')

        expect(tag.element_children).to contain_exactly(img)
        expect(img['class']).to eq('emoji')
        expect(img['src']).to eq('https://example.com/tanuki.png')
        expect(img['alt']).to eq(':tanuki:')
        expect(img['title']).to eq(':tanuki:')
        expect(img['align']).to eq('absmiddle')
      end

      it 'bounds the height without constraining the width', :aggregate_failures do
        img = tag.at_css('img')

        expect(img['height']).to eq('20')
        expect(img['width']).to be_nil
      end
    end
  end
end
