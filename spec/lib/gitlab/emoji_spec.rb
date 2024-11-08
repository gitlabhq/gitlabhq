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
end
