# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownEngines::Cmark, feature_category: :markdown do
  it 'defaults to generating sourcepos' do
    engine = described_class.new({})

    expect(engine.render('# hi')).to eq %(<h1 data-sourcepos="1:1-1:4">hi</h1>\n)
  end

  it 'turns off sourcepos' do
    engine = described_class.new({ no_sourcepos: true })

    expect(engine.render('# hi')).to eq %(<h1>hi</h1>\n)
  end
end
