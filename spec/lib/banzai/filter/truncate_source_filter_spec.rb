# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TruncateSourceFilter do
  include FilterSpecHelper

  let(:short_text) { 'foo' * 10 }
  let(:long_text) { ([short_text] * 10).join(' ') }

  it 'does nothing when limit is unspecified' do
    output = filter(long_text)

    expect(output).to eq(long_text)
  end

  it 'does nothing to a short-enough text' do
    output = filter(short_text, limit: short_text.bytesize)

    expect(output).to eq(short_text)
  end

  it 'truncates UTF-8 text by bytes, on a character boundary' do
    utf8_text = '日本語の文字が大きい'
    truncated = '日...'

    expect(filter(utf8_text, limit: truncated.bytesize)).to eq(truncated)
    expect(filter(utf8_text, limit: utf8_text.bytesize)).to eq(utf8_text)
    expect(filter(utf8_text, limit: utf8_text.mb_chars.size)).not_to eq(utf8_text)
  end
end
