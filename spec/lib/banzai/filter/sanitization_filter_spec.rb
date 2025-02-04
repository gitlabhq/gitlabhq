# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::SanitizationFilter, feature_category: :markdown do
  include FilterSpecHelper

  it_behaves_like 'default allowlist'

  describe 'custom allowlist' do
    it 'customizes the allowlist only once' do
      instance = described_class.new('Foo')
      control_count = instance.allowlist[:transformers].size

      3.times { instance.allowlist }

      expect(instance.allowlist[:transformers].size).to eq control_count
    end

    it 'customizes the allowlist only once for different instances' do
      instance1 = described_class.new('Foo1')
      instance2 = described_class.new('Foo2')
      control_count = instance1.allowlist[:transformers].size

      instance1.allowlist
      instance2.allowlist

      expect(instance1.allowlist[:transformers].size).to eq control_count
      expect(instance2.allowlist[:transformers].size).to eq control_count
    end

    it 'sanitizes `class` attribute from all elements' do
      act = %q(<pre class="code highlight white c"><code>&lt;span class="k"&gt;def&lt;/span&gt;</code></pre>)
      exp = %q(<pre><code>&lt;span class="k"&gt;def&lt;/span&gt;</code></pre>)
      expect(filter(act).to_html).to eq exp
    end

    it 'sanitizes `class` attribute from non-highlight spans' do
      act = %q(<span class="k">def</span>)
      expect(filter(act).to_html).to eq %q(<span>def</span>)
    end

    it 'allows `data-table-*` attributes on `table` elements' do
      html = <<-HTML
        <table data-table-fields="foo" data-table-filter="true" data-table-markdown="true">
        </table>
      HTML

      doc = filter(html)

      expect(doc.at_css('table')['data-table-fields']).to eq 'foo'
      expect(doc.at_css('table')['data-table-filter']).to eq 'true'
      expect(doc.at_css('table')['data-table-markdown']).to eq 'true'
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

    it 'disallows `text-align` property in `style` attribute on other elements' do
      html = <<~HTML
        <div style="text-align: center">Text</div>
      HTML

      doc = filter(html)

      expect(doc.at_css('div')['style']).to be_nil
    end

    it 'allows `span` elements' do
      exp = act = %q(<span>Hello</span>)
      expect(filter(act).to_html).to eq exp
    end

    it 'allows `abbr` elements' do
      exp = act = %q(<abbr title="HyperText Markup Language">HTML</abbr>)
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

    it 'allows `rel=license` in links' do
      exp = act = '<a rel="license" href="http://example.com">rel-license</a>'
      expect(filter(act).to_html).to eq exp
    end

    it 'allows `data-math-style` attribute on `span`, code` and `pre` elements' do
      html = <<-HTML
      <span class="code" data-math-style="inline">something</span>
      <pre class="code" data-math-style="inline">something</pre>
      <code class="code" data-math-style="inline">something</code>
      <div class="code" data-math-style="inline">something</div>
      HTML

      output = <<-HTML
      <span data-math-style="inline">something</span>
      <pre data-math-style="inline">something</pre>
      <code data-math-style="inline">something</code>
      <div>something</div>
      HTML

      expect(filter(html).to_html).to eq(output)
    end

    it 'allows the `data-sourcepos` attribute globally' do
      exp = %q(<p data-sourcepos="1:1-1:10">foo/bar.md</p>)
      act = filter(exp)

      expect(act.to_html).to eq exp
    end

    describe 'footnotes' do
      it 'allows the footnote attributes' do
        exp = <<~HTML
          <section data-footnotes>
          <a href="#fn-first" id="fnref-first" data-footnote-ref data-footnote-backref data-footnote-backref-idx>foo/bar.md</a>
          </section>
        HTML

        act = filter(exp)

        expect(act.to_html).to eq exp
      end

      it 'allows correct footnote id property on links' do
        exp = %q(<a href="#fn-first" id="fnref-first">foo/bar.md</a>)
        act = filter(exp)

        expect(act.to_html).to eq exp
      end

      it 'allows correct footnote id property on li element' do
        exp = %q(<ol><li id="fn-last">footnote</li></ol>)
        act = filter(exp)

        expect(act.to_html).to eq exp
      end

      it 'removes invalid id for footnote links' do
        exp = %q(<a href="#fn1">link</a>)

        %w[fnrefx test xfnref-1].each do |id|
          act = filter(%(<a href="#fn1" id="#{id}">link</a>))

          expect(act.to_html).to eq exp
        end
      end

      it 'removes invalid id for footnote li' do
        exp = %q(<ol><li>footnote</li></ol>)

        %w[fnx test xfn-1].each do |id|
          act = filter(%(<ol><li id="#{id}">footnote</li></ol>))

          expect(act.to_html).to eq exp
        end
      end
    end

    describe 'link anchors' do
      it 'allows id property on anchor links' do
        exp = %q(<a href="#this-is-a-header" class="anchor" id="user-content-this-is-a-header"></a>)
        act = filter(exp)

        expect(act.to_html).to eq exp
      end

      it 'removes id property for non-anchor links' do
        exp = %q(<a href="#this-is-a-header"></a>)
        act = filter(%q(<a href="#this-is-a-header" id="user-content-this-is-a-header"></a>))

        expect(act.to_html).to eq exp
      end

      it 'removes id property for non-user-content links' do
        exp = %q(<a href="#this-is-a-header" class="anchor"></a>)
        act = filter(%q(<a href="#this-is-a-header" class="anchor" id="this-is-a-header"></a>))

        expect(act.to_html).to eq exp
      end

      it 'removes class property for non-anchor links' do
        exp = %q(<a href="#this-is-a-header"></a>)
        act = filter(%q(<a href="#this-is-a-header" class="some-other-class anchor"></a>))

        expect(act.to_html).to eq exp
      end
    end
  end

  it_behaves_like 'does not use pipeline timing check'

  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
    let(:expected_result) { described_class::COMPLEX_MARKDOWN_MESSAGE }
    let(:expected_timeout) { described_class::SANITIZATION_RENDER_TIMEOUT }
  end
end
