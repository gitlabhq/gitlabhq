# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Emoji do
  describe '.emoji_image_tag' do
    it 'returns emoji image tag' do
      emoji_image = described_class.emoji_image_tag('emoji_one', 'src_url')

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"src_url\" title=\":emoji_one:\" alt=\":emoji_one:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end

    it 'escapes emoji image attrs to prevent XSS' do
      xss_payload = "<script>alert(1)</script>"
      escaped_xss_payload = html_escape(xss_payload)

      emoji_image = described_class.emoji_image_tag(xss_payload, 'http://aaa#' + xss_payload)

      expect(emoji_image).to eq("<img class=\"emoji\" src=\"http://aaa##{escaped_xss_payload}\" title=\":#{escaped_xss_payload}:\" alt=\":#{escaped_xss_payload}:\" height=\"20\" width=\"20\" align=\"absmiddle\" />")
    end
  end

  describe '.gl_emoji_tag' do
    it 'returns gl emoji tag if emoji is found' do
      emoji = TanukiEmoji.find_by_alpha_code('small_airplane')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to eq('<gl-emoji title="small airplane" data-name="airplane_small" data-unicode-version="7.0">🛩</gl-emoji>')
    end

    it 'returns nil if emoji is not found' do
      emoji = TanukiEmoji.find_by_alpha_code('random')
      gl_tag = described_class.gl_emoji_tag(emoji)

      expect(gl_tag).to be_nil
    end
  end
end
