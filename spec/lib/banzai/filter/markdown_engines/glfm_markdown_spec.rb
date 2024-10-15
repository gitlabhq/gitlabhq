# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownEngines::GlfmMarkdown, feature_category: :markdown do
  it 'defaults to generating sourcepos' do
    engine = described_class.new({})
    expected = <<~TEXT
      <h1 data-sourcepos="1:1-1:4"><a href="#hi" aria-hidden="true" class="anchor" id="user-content-hi"></a>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off sourcepos' do
    engine = described_class.new({ no_sourcepos: true })
    expected = <<~TEXT
      <h1><a href="#hi" aria-hidden="true" class="anchor" id="user-content-hi"></a>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off header anchors' do
    engine = described_class.new({ no_header_anchors: true, no_sourcepos: true })
    expected = <<~TEXT
      <h1>hi</h1>
    TEXT

    expect(engine.render('# hi')).to eq expected
  end

  it 'turns off autolinking' do
    engine = described_class.new({ autolink: false, no_sourcepos: true })
    expected = <<~TEXT
      <p>http://example.com</p>
    TEXT

    expect(engine.render('http://example.com')).to eq expected
  end
end
