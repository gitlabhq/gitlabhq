# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Pipeline::EmojiPipeline do
  def parse(text)
    described_class.to_html(text, {})
  end

  it 'replaces emoji' do
    expected_result = "Hello world #{Gitlab::Emoji.gl_emoji_tag('100')}"

    expect(parse('Hello world :100:')).to eq(expected_result)
  end

  it 'filters out HTML tags' do
    expected_result = "Hello &lt;b&gt;world&lt;/b&gt; #{Gitlab::Emoji.gl_emoji_tag('100')}"

    expect(parse('Hello <b>world</b> :100:')).to eq(expected_result)
  end
end
