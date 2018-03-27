require 'spec_helper'

describe Banzai::Filter::SanitizationFilter do
  include FilterSpecHelper

  describe 'default whitelist' do
    it 'sanitizes tags that are not whitelisted' do
      act = %q{<textarea>no inputs</textarea> and <blink>no blinks</blink>}
      exp = 'no inputs and no blinks'
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes tag attributes' do
      act = %q{<a href="http://example.com/bar.html" onclick="bar">Text</a>}
      exp = %q{<a href="http://example.com/bar.html">Text</a>}
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes javascript in attributes' do
      act = %q(<a href="javascript:alert('foo')">Text</a>)
      exp = '<a>Text</a>'
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes mixed-cased javascript in attributes' do
      act = %q(<a href="javaScript:alert('foo')">Text</a>)
      exp = '<a>Text</a>'
      expect(filter(act).to_html).to eq exp
    end

    it 'allows whitelisted HTML tags from the user' do
      exp = act = "<dl>\n<dt>Term</dt>\n<dd>Definition</dd>\n</dl>"
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes `class` attribute on any element' do
      act = %q{<strong class="foo">Strong</strong>}
      expect(filter(act).to_html).to eq %q{<strong>Strong</strong>}
    end

    it 'sanitizes `id` attribute on any element' do
      act = %q{<em id="foo">Emphasis</em>}
      expect(filter(act).to_html).to eq %q{<em>Emphasis</em>}
    end
  end

  describe 'custom whitelist' do
    it 'customizes the whitelist only once' do
      instance = described_class.new('Foo')
      control_count = instance.whitelist[:transformers].size

      3.times { instance.whitelist }

      expect(instance.whitelist[:transformers].size).to eq control_count
    end

    it 'sanitizes `class` attribute from all elements' do
      act = %q{<pre class="code highlight white c"><code>&lt;span class="k"&gt;def&lt;/span&gt;</code></pre>}
      exp = %q{<pre><code>&lt;span class="k"&gt;def&lt;/span&gt;</code></pre>}
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes `class` attribute from non-highlight spans' do
      act = %q{<span class="k">def</span>}
      expect(filter(act).to_html).to eq %q{<span>def</span>}
    end

    it 'allows `text-align` property in `style` attribute on table elements' do
      html = <<~HTML
      <table>
        <tr><th style="text-align: center">Head</th></tr>
        <tr><td style="text-align: right">Body</th></tr>
      </table>
      HTML

      doc = filter(html)

      expect(doc.at_css('th')['style']).to eq 'text-align: center'
      expect(doc.at_css('td')['style']).to eq 'text-align: right'
    end

    it 'disallows other properties in `style` attribute on table elements' do
      html = <<~HTML
        <table>
          <tr><th style="text-align: foo">Head</th></tr>
          <tr><td style="position: fixed; height: 50px; width: 50px; background: red; z-index: 999; font-size: 36px; text-align: center">Body</th></tr>
        </table>
      HTML

      doc = filter(html)

      expect(doc.at_css('th')['style']).to be_nil
      expect(doc.at_css('td')['style']).to eq 'text-align: center'
    end

    it 'allows `span` elements' do
      exp = act = %q{<span>Hello</span>}
      expect(filter(act).to_html).to eq exp
    end

    it 'allows `abbr` elements' do
      exp = act = %q{<abbr title="HyperText Markup Language">HTML</abbr>}
      expect(filter(act).to_html).to eq exp
    end

    it 'disallows the `name` attribute globally, allows on `a`' do
      html = <<~HTML
        <img name="getElementById" src="">
        <span name="foo" class="bar">Hi</span>
        <a name="foo" class="bar">Bye</a>
      HTML

      doc = filter(html)

      expect(doc.at_css('img')).not_to have_attribute('name')
      expect(doc.at_css('span')).not_to have_attribute('name')
      expect(doc.at_css('a')).to have_attribute('name')
    end

    it 'allows `summary` elements' do
      exp = act = '<summary>summary line</summary>'
      expect(filter(act).to_html).to eq exp
    end

    it 'allows `details` elements' do
      exp = act = '<details>long text goes here</details>'
      expect(filter(act).to_html).to eq exp
    end

    it 'allows `data-math-style` attribute on `code` and `pre` elements' do
      html = <<-HTML
      <pre class="code" data-math-style="inline">something</pre>
      <code class="code" data-math-style="inline">something</code>
      <div class="code" data-math-style="inline">something</div>
      HTML

      output = <<-HTML
      <pre data-math-style="inline">something</pre>
      <code data-math-style="inline">something</code>
      <div>something</div>
      HTML

      expect(filter(html).to_html).to eq(output)
    end

    it 'removes `rel` attribute from `a` elements' do
      act = %q{<a href="#" rel="nofollow">Link</a>}
      exp = %q{<a href="#">Link</a>}

      expect(filter(act).to_html).to eq exp
    end

    # Adapted from the Sanitize test suite: http://git.io/vczrM
    protocols = {
      'protocol-based JS injection: simple, no spaces' => {
        input:  '<a href="javascript:alert(\'XSS\');">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: simple, spaces before' => {
        input:  '<a href="javascript    :alert(\'XSS\');">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: simple, spaces after' => {
        input:  '<a href="javascript:    alert(\'XSS\');">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: simple, spaces before and after' => {
        input:  '<a href="javascript    :   alert(\'XSS\');">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: preceding colon' => {
        input:  '<a href=":javascript:alert(\'XSS\');">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: UTF-8 encoding' => {
        input:  '<a href="javascript&#58;">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: long UTF-8 encoding' => {
        input:  '<a href="javascript&#0058;">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: long UTF-8 encoding without semicolons' => {
        input:  '<a href=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: hex encoding' => {
        input:  '<a href="javascript&#x3A;">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: long hex encoding' => {
        input:  '<a href="javascript&#x003A;">foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: hex encoding without semicolons' => {
        input:  '<a href=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>foo</a>',
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: null char' => {
        input:  "<a href=java\0script:alert(\"XSS\")>foo</a>",
        output: '<a href="java"></a>'
      },

      'protocol-based JS injection: invalid URL char' => {
        input: '<img src=java\script:alert("XSS")>',
        output: '<img>'
      },

      'protocol-based JS injection: Unicode' => {
        input: %Q(<a href="\u0001java\u0003script:alert('XSS')">foo</a>),
        output: '<a>foo</a>'
      },

      'protocol-based JS injection: spaces and entities' => {
        input:  '<a href=" &#14;  javascript:alert(\'XSS\');">foo</a>',
        output: '<a href="">foo</a>'
      },

      'protocol whitespace' => {
        input: '<a href=" http://example.com/"></a>',
        output: '<a href="http://example.com/"></a>'
      }
    }

    protocols.each do |name, data|
      it "disallows #{name}" do
        doc = filter(data[:input])

        expect(doc.to_html).to eq data[:output]
      end
    end

    it 'disallows data links' do
      input = '<a href="data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K">XSS</a>'
      output = filter(input)

      expect(output.to_html).to eq '<a>XSS</a>'
    end

    it 'disallows vbscript links' do
      input = '<a href="vbscript:alert(document.domain)">XSS</a>'
      output = filter(input)

      expect(output.to_html).to eq '<a>XSS</a>'
    end

    it 'disallows invalid URIs' do
      expect(Addressable::URI).to receive(:parse).with('foo://example.com')
        .and_raise(Addressable::URI::InvalidURIError)

      input = '<a href="foo://example.com">Foo</a>'
      output = filter(input)

      expect(output.to_html).to eq '<a>Foo</a>'
    end

    it 'allows non-standard anchor schemes' do
      exp = %q{<a href="irc://irc.freenode.net/git">IRC</a>}
      act = filter(exp)

      expect(act.to_html).to eq exp
    end

    it 'allows relative links' do
      exp = %q{<a href="foo/bar.md">foo/bar.md</a>}
      act = filter(exp)

      expect(act.to_html).to eq exp
    end
  end
end
