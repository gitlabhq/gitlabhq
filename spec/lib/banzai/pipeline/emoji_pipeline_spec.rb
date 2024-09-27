# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::EmojiPipeline, feature_category: :markdown do
  let(:emoji) { TanukiEmoji.find_by_alpha_code('100') }

  def parse(text)
    described_class.to_html(text, {})
  end

  it_behaves_like 'sanitize pipeline'

  it 'replaces emoji' do
    expected_result = "Hello world #{Gitlab::Emoji.gl_emoji_tag(emoji)}"

    expect(parse('Hello world :100:')).to eq(expected_result)
  end

  it 'filters out HTML tags' do
    expected_result = "Hello &lt;b&gt;world&lt;/b&gt; #{Gitlab::Emoji.gl_emoji_tag(emoji)}"

    expect(parse('Hello <b>world</b> :100:')).to eq(expected_result)
  end
end
