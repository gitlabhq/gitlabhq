# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TrimWhitespaceFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'trims leading and trailing whitespace' do
    expect(filter(" text ").to_html).to eq('text')
  end

  it 'trims across multiple adjacent boundary text nodes' do
    doc = Banzai::PipelineBase.parse('')
    doc.add_child(Nokogiri::XML::Text.new('  ', doc))
    doc.add_child(Nokogiri::XML::Text.new(' text', doc))

    expect(described_class.call(doc, {}).to_html).to eq('text')
  end

  it 'reduces whitespace-only content to an empty document' do
    expect(filter("  \n ").to_html).to eq('')
  end

  it 'preserves interior whitespace' do
    expect(filter(" one \n two ").to_html).to eq("one \n two")
  end

  it 'does not trim inside elements at the boundary' do
    expect(filter('<em> text </em>').to_html).to eq('<em> text </em>')
  end
end
