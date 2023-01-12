# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MathFilter do
  using RSpec::Parameterized::TableSyntax
  include FilterSpecHelper

  shared_examples 'inline math' do
    it 'removes surrounding dollar signs and adds class code, math and js-render-math' do
      doc = filter(text)
      expected = result_template.gsub('<math>', '<code class="code math js-render-math" data-math-style="inline">')
      expected.gsub!('</math>', '</code>')

      expect(doc.to_s).to eq expected
    end
  end

  shared_examples 'display math' do
    let_it_be(:template_prefix_with_pre) { '<pre class="code math js-render-math" data-math-style="display"><code>' }
    let_it_be(:template_prefix_with_code) { '<code class="code math js-render-math" data-math-style="display">' }
    let(:use_pre_tags) { false }

    it 'removes surrounding dollar signs and adds class code, math and js-render-math' do
      doc = filter(text)

      template_prefix = use_pre_tags ? template_prefix_with_pre : template_prefix_with_code
      template_suffix = "</code>#{'</pre>' if use_pre_tags}"
      expected = result_template.gsub('<math>', template_prefix)
      expected.gsub!('</math>', template_suffix)

      expect(doc.to_s).to eq expected
    end
  end

  describe 'inline math using $...$ syntax' do
    context 'with valid syntax' do
      where(:text, :result_template) do
        '$2+2$'                                  | '<math>2+2</math>'
        '$22+1$ and $22 + a^2$'                  | '<math>22+1</math> and <math>22 + a^2</math>'
        '$22 and $2+2$'                          | '$22 and <math>2+2</math>'
        '$2+2$ $22 and flightjs/Flight$22 $2+2$' | '<math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math>'
        '$1/2$ &lt;b&gt;test&lt;/b&gt;'          | '<math>1/2</math> &lt;b&gt;test&lt;/b&gt;'
        '$a!$'                                   | '<math>a!</math>'
        '$x$'                                    | '<math>x</math>'
      end

      with_them do
        it_behaves_like 'inline math'
      end
    end

    it 'does not handle dollar literals properly' do
      doc = filter('$20+30\$$')
      expected = '<code class="code math js-render-math" data-math-style="inline">20+30\\</code>$'

      expect(doc.to_s).to eq expected
    end
  end

  describe 'inline math using $`...`$ syntax' do
    context 'with valid syntax' do
      where(:text, :result_template) do
        '$<code>2+2</code>$'                                               | '<math>2+2</math>'
        '$<code>22+1</code>$ and $<code>22 + a^2</code>$'                  | '<math>22+1</math> and <math>22 + a^2</math>'
        '$22 and $<code>2+2</code>$'                                       | '$22 and <math>2+2</math>'
        '$<code>2+2</code>$ $22 and flightjs/Flight$22 $<code>2+2</code>$' | '<math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math>'
        'test $$<code>2+2</code>$$ test'                                   | 'test $<math>2+2</math>$ test'
      end

      with_them do
        it_behaves_like 'inline math'
      end
    end
  end

  describe 'inline display math using $$...$$ syntax' do
    context 'with valid syntax' do
      where(:text, :result_template) do
        '$$2+2$$'                                    | '<math>2+2</math>'
        '$$   2+2  $$'                               | '<math>2+2</math>'
        '$$22+1$$ and $$22 + a^2$$'                  | '<math>22+1</math> and <math>22 + a^2</math>'
        '$22 and $$2+2$$'                            | '$22 and <math>2+2</math>'
        '$$2+2$$ $22 and flightjs/Flight$22 $$2+2$$' | '<math>2+2</math> $22 and flightjs/Flight$22 <math>2+2</math>'
        'flightjs/Flight$22 and $$a^2 + b^2 = c^2$$' | 'flightjs/Flight$22 and <math>a^2 + b^2 = c^2</math>'
        '$$a!$$'                                     | '<math>a!</math>'
        '$$x$$'                                      | '<math>x</math>'
        '$$20,000 and $$30,000'                      | '<math>20,000 and</math>30,000'
      end

      with_them do
        it_behaves_like 'display math'
      end
    end
  end

  describe 'block display math using $$\n...\n$$ syntax' do
    context 'with valid syntax' do
      where(:text, :result_template) do
        "$$\n2+2\n$$"      | "<math>2+2</math>"
        "$$\n2+2\n3+4\n$$" | "<math>2+2\n3+4</math>"
      end

      with_them do
        it_behaves_like 'display math' do
          let(:use_pre_tags) { true }
        end
      end
    end
  end

  describe 'display math using ```math...``` syntax' do
    it 'adds data-math-style display attribute to display math' do
      doc = filter('<pre lang="math"><code>2+2</code></pre>')
      pre = doc.xpath('descendant-or-self::pre').first

      expect(pre['data-math-style']).to eq 'display'
    end

    it 'adds js-render-math class to display math' do
      doc = filter('<pre lang="math"><code>2+2</code></pre>')
      pre = doc.xpath('descendant-or-self::pre').first

      expect(pre[:class]).to include("js-render-math")
    end

    it 'ignores code blocks that are not math' do
      input = '<pre lang="plaintext"><code>2+2</code></pre>'
      doc = filter(input)

      expect(doc.to_s).to eq input
    end

    it 'requires the pre to contain both code and math' do
      input = '<pre lang="math">something</pre>'
      doc = filter(input)

      expect(doc.to_s).to eq input
    end

    it 'dollar signs around to display math' do
      doc = filter('$<pre lang="math"><code>2+2</code></pre>$')
      before = doc.xpath('descendant-or-self::text()[1]').first
      after = doc.xpath('descendant-or-self::text()[3]').first

      expect(before.to_s).to eq '$'
      expect(after.to_s).to eq '$'
    end
  end

  describe 'unrecognized syntax' do
    where(:text) do
      [
        '<code>2+2</code>',
        'test $<code>2+2</code> test',
        'test <code>2+2</code>$ test',
        '<em>$</em><code>2+2</code><em>$</em>',
        '$20,000 and $30,000',
        '$20,000 in $USD',
        '$ a^2 $',
        "test $$\n2+2\n$$",
        "$\n$",
        '$$$'
      ]
    end

    with_them do
      it 'is ignored' do
        expect(filter(text).to_s).to eq text
      end
    end
  end

  it 'handles multiple styles in one text block' do
    doc = filter('$<code>2+2</code>$ + $3+3$ + $$4+4$$')

    expect(doc.search('.js-render-math').count).to eq(3)
    expect(doc.search('[data-math-style="inline"]').count).to eq(2)
    expect(doc.search('[data-math-style="display"]').count).to eq(1)
  end

  it 'limits how many elements can be marked as math' do
    stub_const('Banzai::Filter::MathFilter::RENDER_NODES_LIMIT', 2)

    doc = filter('$<code>2+2</code>$ + $<code>3+3</code>$ + $<code>4+4</code>$')

    expect(doc.search('.js-render-math').count).to eq(2)
  end
end
