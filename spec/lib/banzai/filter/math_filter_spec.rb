require 'spec_helper'

describe Banzai::Filter::MathFilter, lib: true do
  include FilterSpecHelper

  it 'leaves regular inline code unchanged' do
    input = "<code>2+2</code>"
    doc = filter(input)
    expect(doc.to_s).to eq input
  end

  it 'removes surrounding dollar signs and adds class' do
    doc = filter("$<code>2+2</code>$")
    expect(doc.to_s).to eq '<code class="code math" data-math-style="inline">2+2</code>'
  end

  it 'only removes surrounding dollar signs' do
    doc = filter("test $<code>2+2</code>$ test")
    expect(doc.to_s).to eq 'test <code class="code math" data-math-style="inline">2+2</code> test'
  end

  it 'only removes surrounding single dollar sign' do
    doc = filter("test $$<code>2+2</code>$$ test")
    expect(doc.to_s).to eq 'test $<code class="code math" data-math-style="inline">2+2</code>$ test'
  end

  it 'ignores cases with missing dolar sign at the end' do
    input = "test $<code>2+2</code> test"
    doc = filter(input)
    expect(doc.to_s).to eq input
  end

  it 'ignores cases with missing dolar sign at the beginning' do
    input = "test <code>2+2</code>$ test"
    doc = filter(input)
    expect(doc.to_s).to eq input
  end

  it 'ignores dollar signs if it is not adjacent' do
    input = '<p>We check strictly $<code>2+2</code> and  <code>2+2</code>$ </p>'
    doc = filter(input)
    expect(doc.to_s).to eq input
  end

end
