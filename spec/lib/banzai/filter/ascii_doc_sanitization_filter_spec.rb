# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AsciiDocSanitizationFilter, feature_category: :wiki do
  include FilterSpecHelper

  it 'preserves footnotes refs' do
    result = filter('<p>This paragraph has a footnote.<sup>[<a id="_footnoteref_1" href="#_footnotedef_1" title="View footnote.">1</a>]</sup></p>').to_html
    expect(result).to eq('<p>This paragraph has a footnote.<sup>[<a id="_footnoteref_1" href="#_footnotedef_1" title="View footnote.">1</a>]</sup></p>')
  end

  it 'preserves footnotes defs' do
    result = filter('<div id="_footnotedef_1">
<a href="#_footnoteref_1">1</a>. This is the text of the footnote.</div>').to_html
    expect(result).to eq(%(<div id="_footnotedef_1">
<a href="#_footnoteref_1">1</a>. This is the text of the footnote.</div>))
  end

  it 'preserves user-content- prefixed ids on anchors' do
    result = filter('<p><a id="user-content-cross-references"></a>A link to another location within an AsciiDoc document.</p>').to_html
    expect(result).to eq(%(<p><a id="user-content-cross-references"></a>A link to another location within an AsciiDoc document.</p>))
  end

  context 'with blocks' do
    %w[openblock sidebarblock exampleblock].each do |block|
      it "preserves user-content- prefixed ids on div (#{block})" do
        html_content = <<~HTML
          <div id="user-content-#{block}" class="#{block}">
            <div class="content">
              <div class="paragraph">
                <p>This is a #{block} block</p>
              </div>
            </div>
          </div>
        HTML

        output = <<~SANITIZED_HTML
          <div id="user-content-#{block}" class="#{block}">
            <div>
              <div>
                <p>This is a #{block} block</p>
              </div>
            </div>
          </div>
        SANITIZED_HTML
        expect(filter(html_content).to_html).to eq(output)
      end
    end
  end

  it 'preserves section anchor ids' do
    result = filter(%(<h2 id="user-content-first-section">
<a class="anchor" href="#user-content-first-section"></a>First section</h2>)).to_html
    expect(result).to eq(%(<h2 id="user-content-first-section">
<a class="anchor" href="#user-content-first-section"></a>First section</h2>))
  end

  it 'removes non prefixed ids' do
    result = filter('<p><a id="cross-references"></a>A link to another location within an AsciiDoc document.</p>').to_html
    expect(result).to eq(%(<p><a></a>A link to another location within an AsciiDoc document.</p>))
  end

  it 'preserves toc class' do
    result = filter('<div id="toc" class="toc">foo</div>').to_html
    expect(result).to eq('<div class="toc">foo</div>')
  end

  describe '#customize_allowlist' do
    let(:filter) { described_class.new('') }

    it 'customizes the allowlist with required elements and attributes' do
      allowlist = {
        elements: [],
        attributes: {
          'pre' => ['existing-attr'],
          'div' => ['existing-div-attr'],
          'a' => ['href']
        },
        transformers: []
      }

      result = filter.send(:customize_allowlist, allowlist)

      expect(result[:elements]).to include('mark')
      expect(result[:attributes]['pre']).to include('data-lang')
      expect(result[:attributes]['span']).to eq(%w[class])
      expect(result[:attributes]['a']).to include('id', 'class')
      expect(result[:attributes]['div']).to include('id', 'class')

      # Test the actual headers that are present (h2-h6, not h1)
      expect(result[:attributes]).to have_key('h2')
      expect(result[:attributes]).to have_key('h3')
      expect(result[:attributes]['h2']).to eq(%w[id])
      expect(result[:attributes]['h3']).to eq(%w[id])

      expect(result[:transformers].length).to eq(2)
    end
  end
end
