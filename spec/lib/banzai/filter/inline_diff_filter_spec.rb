# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineDiffFilter, feature_category: :source_code_management do
  include FilterSpecHelper

  it 'adds inline diff span tags for deletions when using square brackets' do
    doc = "START [-something deleted-] END"
    expect(filter(doc).to_html).to eq('START <span class="idiff left right deletion">something deleted</span> END')
  end

  it 'adds inline diff span tags for deletions when using curley braces' do
    doc = "START {-something deleted-} END"
    expect(filter(doc).to_html).to eq('START <span class="idiff left right deletion">something deleted</span> END')
  end

  it 'does not add inline diff span tags when a closing tag is not provided' do
    doc = "START [- END"
    expect(filter(doc).to_html).to eq(doc)
  end

  it 'adds inline span tags for additions when using square brackets' do
    doc = "START [+something added+] END"
    expect(filter(doc).to_html).to eq('START <span class="idiff left right addition">something added</span> END')
  end

  it 'adds inline span tags for additions  when using curley braces' do
    doc = "START {+something added+} END"
    expect(filter(doc).to_html).to eq('START <span class="idiff left right addition">something added</span> END')
  end

  it 'does not add inline diff span tags when a closing addition tag is not provided' do
    doc = "START {+ END"
    expect(filter(doc).to_html).to eq(doc)
  end

  it 'does not add inline diff span tags when the tags do not match' do
    examples = [
      "{+ additions +]",
      "[+ additions +}",
      "{- delletions -]",
      "[- delletions -}"
    ]

    examples.each do |doc|
      expect(filter(doc).to_html).to eq(doc)
    end
  end

  it 'prevents user-land html being injected' do
    doc = "START {+&lt;script&gt;alert('I steal cookies')&lt;/script&gt;+} END"
    expect(filter(doc).to_html).to eq("START <span class=\"idiff left right addition\">&lt;script&gt;alert('I steal cookies')&lt;/script&gt;</span> END")
  end

  it 'preserves content inside pre tags' do
    doc = "<pre>START {+something added+} END</pre>"
    expect(filter(doc).to_html).to eq(doc)
  end

  it 'preserves content inside code tags' do
    doc = "<code>START {+something added+} END</code>"
    expect(filter(doc).to_html).to eq(doc)
  end

  it 'preserves content inside tt tags' do
    doc = "<tt>START {+something added+} END</tt>"
    expect(filter(doc).to_html).to eq(doc)
  end

  it 'protects against malicious backtracking' do
    doc = '[-{-' * 250_000

    expect do
      Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(doc) }
    end.not_to raise_error
  end

  it_behaves_like 'pipeline timing check'

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { '[+added+] [+added+] [+added+]' }
    let(:ends_with) { '</span> [+added+]' }
  end
end
