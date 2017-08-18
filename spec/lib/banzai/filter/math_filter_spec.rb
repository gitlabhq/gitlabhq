require 'spec_helper'

describe Banzai::Filter::MathFilter do
  include FilterSpecHelper

  it 'leaves regular inline code unchanged' do
    input = "<code>2+2</code>"
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'removes surrounding dollar signs and adds class code, math and js-render-math' do
    doc = filter("$<code>2+2</code>$")

    expect(doc.to_s).to eq '<code class="code math js-render-math" data-math-style="inline">2+2</code>'
  end

  it 'only removes surrounding dollar signs' do
    doc = filter("test $<code>2+2</code>$ test")
    before = doc.xpath('descendant-or-self::text()[1]').first
    after = doc.xpath('descendant-or-self::text()[3]').first

    expect(before.to_s).to eq 'test '
    expect(after.to_s).to eq ' test'
  end

  it 'only removes surrounding single dollar sign' do
    doc = filter("test $$<code>2+2</code>$$ test")
    before = doc.xpath('descendant-or-self::text()[1]').first
    after = doc.xpath('descendant-or-self::text()[3]').first

    expect(before.to_s).to eq 'test $'
    expect(after.to_s).to eq '$ test'
  end

  it 'adds data-math-style inline attribute to inline math' do
    doc = filter('$<code>2+2</code>$')
    code = doc.xpath('descendant-or-self::code').first

    expect(code['data-math-style']).to eq 'inline'
  end

  it 'adds class code and math to inline math' do
    doc = filter('$<code>2+2</code>$')
    code = doc.xpath('descendant-or-self::code').first

    expect(code[:class]).to include("code")
    expect(code[:class]).to include("math")
  end

  it 'adds js-render-math class to inline math' do
    doc = filter('$<code>2+2</code>$')
    code = doc.xpath('descendant-or-self::code').first

    expect(code[:class]).to include("js-render-math")
  end

  # Cases with faulty syntax. Should be a no-op

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

  it 'ignores dollar signs if they are inside another element' do
    input = '<p>We check strictly <em>$</em><code>2+2</code><em>$</em></p>'
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  # Display math

  it 'adds data-math-style display attribute to display math' do
    doc = filter('<pre class="code highlight js-syntax-highlight math" v-pre="true"><code>2+2</code></pre>')
    pre = doc.xpath('descendant-or-self::pre').first

    expect(pre['data-math-style']).to eq 'display'
  end

  it 'adds js-render-math class to display math' do
    doc = filter('<pre class="code highlight js-syntax-highlight math" v-pre="true"><code>2+2</code></pre>')
    pre = doc.xpath('descendant-or-self::pre').first

    expect(pre[:class]).to include("js-render-math")
  end

  it 'ignores code blocks that are not math' do
    input = '<pre class="code highlight js-syntax-highlight plaintext" v-pre="true"><code>2+2</code></pre>'
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'requires the pre to contain both code and math' do
    input = '<pre class="highlight js-syntax-highlight plaintext math" v-pre="true"><code>2+2</code></pre>'
    doc = filter(input)

    expect(doc.to_s).to eq input
  end

  it 'dollar signs around to display math' do
    doc = filter('$<pre class="code highlight js-syntax-highlight math" v-pre="true"><code>2+2</code></pre>$')
    before = doc.xpath('descendant-or-self::text()[1]').first
    after = doc.xpath('descendant-or-self::text()[3]').first

    expect(before.to_s).to eq '$'
    expect(after.to_s).to eq '$'
  end
end
