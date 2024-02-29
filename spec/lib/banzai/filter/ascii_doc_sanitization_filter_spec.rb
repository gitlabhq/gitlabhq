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
end
