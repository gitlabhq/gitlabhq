# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::PathologicalMarkdownFilter do
  include FilterSpecHelper

  let_it_be(:short_text) { '![a' * 5 }
  let_it_be(:long_text) { ([short_text] * 10).join(' ') }
  let_it_be(:with_images_text) { "![One ![one](one.jpg) #{'and\n' * 200} ![two ![two](two.jpg)" }

  it 'detects a significat number of unclosed image links' do
    msg = <<~TEXT
      _Unable to render markdown - too many unclosed markdown image links detected._
    TEXT

    expect(filter(long_text)).to eq(msg.strip)
  end

  it 'does nothing when there are only a few unclosed image links' do
    expect(filter(short_text)).to eq(short_text)
  end

  it 'does nothing when there are only a few unclosed image links and images' do
    expect(filter(with_images_text)).to eq(with_images_text)
  end
end
