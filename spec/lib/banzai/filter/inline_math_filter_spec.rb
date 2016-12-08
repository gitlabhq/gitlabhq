require 'spec_helper'

describe Banzai::Filter::InlineMathFilter, lib: true do
  include FilterSpecHelper

  it 'leaves regular inline code unchanged' do
    doc = filter("<code>2+2</code>")
    expect(doc.to_s).to eq "<code>2+2</code>"
  end

  it 'removes surrounding dollar signs and adds class' do
    doc = filter("$<code>2+2</code>$")
    expect(doc.to_s).to eq '<code class="code math">2+2</code>'
  end

  it 'only removes surrounding dollar signs' do
    doc = filter("test $<code>2+2</code>$ test")
    expect(doc.to_s).to eq 'test <code class="code math">2+2</code> test'
  end

  it 'only removes surrounding single dollar sign' do
    doc = filter("test $$<code>2+2</code>$$ test")
    expect(doc.to_s).to eq 'test $<code class="code math">2+2</code>$ test'
  end

  it 'ignores cases with missing dolar sign at the end' do
    doc = filter("test $<code>2+2</code> test")
    expect(doc.to_s).to eq 'test $<code>2+2</code> test'
  end

  it 'ignores cases with missing dolar sign at the beginning' do
    doc = filter("test <code>2+2</code>$ test")
    expect(doc.to_s).to eq 'test <code>2+2</code>$ test'
  end

  it 'ignores dollar signs if it is not adjacent' do
    doc = filter("$test <code>2+2</code>$ test")
    expect(doc.to_s).to eq '$test <code>2+2</code>$ test'
  end

end
