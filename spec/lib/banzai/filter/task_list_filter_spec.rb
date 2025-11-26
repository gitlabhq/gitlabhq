# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TaskListFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'adds `<task-button></task-button>` to every list item' do
    doc = reference_filter(<<~MARKDOWN)
      * [ ] testing item 1
      * [x] testing item 2
    MARKDOWN

    expect(doc.xpath('.//li//task-button').count).to eq(2)
  end

  it 'adds `aria-label` to every checkbox in the list' do
    # Some of these test cases are not possible to encounter in practice:
    # they imply these tags or attributes made it past SanitizationFilter.
    # Even if they were inserted into aria-label, there is no XSS possible as aria-label is text.
    doc = reference_filter(<<~MARKDOWN)
      * [ ] testing item 1
      * [x] testing item 2
      * [~] testing item 3
      * [~] testing item 4 this is a very long label that should be truncated at some point but where does it truncate?
      * [ ] <div class="js-snippet" data-malacious="something">suspicious item</div>
      * [ ] <div onclick="alert(0)">suspicious item 2</div>
      * [~] <svg><script>&#97;lert(1)</script></svg>
      * [~] <svg><script>&#x61;lert(1)</script></svg>
      * [~] <svg><script>x="&quot;,alert(1)//";</script></svg>
      * [~] &quot; hijacking quotes " a ' b &apos; c
    MARKDOWN

    aria_labels = doc.xpath('.//li//input/@aria-label')

    expect(aria_labels.count).to eq(10)
    expect(aria_labels[0].value).to eq('Check option: testing item 1')
    expect(aria_labels[1].value).to eq('Check option: testing item 2')
    expect(aria_labels[2].value).to eq('Check option: testing item 3')
    expect(aria_labels[3].value).to eq('Check option: testing item 4 this is a very long label that should be truncated at some point but where does it…')
    expect(aria_labels[4].value).to eq('Check option: suspicious item')
    expect(aria_labels[5].value).to eq('Check option: suspicious item 2')
    expect(aria_labels[6].value).to eq('Check option: alert(1)')
    expect(aria_labels[7].value).to eq('Check option: alert(1)')
    expect(aria_labels[8].value).to eq('Check option: x=&quot;&quot;,alert(1)//&quot;;')
    expect(aria_labels[9].value).to eq("Check option: \" hijacking quotes \" a ' b ' c")
  end

  it 'ignores checkbox on following line' do
    doc = reference_filter(<<~MARKDOWN)
      * one
        * foo
          [ ] bar
    MARKDOWN

    expect(doc.xpath('.//li//input').count).to eq(0)
  end

  it 'supports all kinds of spaces for unchecked items' do
    doc = reference_filter(<<~MARKDOWN)
      - [\u00a0] NO-BREAK SPACE (U+00A0)
      - [\u2007] FIGURE SPACE (U+2007)
      - [\u202f] NARROW NO-BREAK SPACE (U+202F)
      - [\u2009] THIN SPACE (U+2009)
      - [\u0020] SPACE (U+0020)
      - [x] Checked!
    MARKDOWN

    expect(doc.css('input[checked]').count).to eq(1)
    expect(doc.css('input:not([checked])').count).to eq(5)
  end

  describe 'inapplicable list items' do
    shared_examples 'a valid inapplicable task list item' do |markdown, s_nodes_expected|
      it "behaves correctly for `#{markdown}`" do
        doc = reference_filter("* #{markdown}")

        expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(1)
        expect(doc.css('li.inapplicable s.inapplicable').count).to eq(s_nodes_expected)
      end
    end

    shared_examples 'an invalid inapplicable task list item' do |markdown|
      it "does nothing for `#{markdown}`" do
        doc = reference_filter("* #{markdown}")

        expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(0)
      end
    end

    it_behaves_like 'a valid inapplicable task list item', '[~] foobar', 1
    it_behaves_like 'a valid inapplicable task list item', '[~] foo <em>bar</em>', 2
    it_behaves_like 'an invalid inapplicable task list item', '[ ] foobar'
    it_behaves_like 'an invalid inapplicable task list item', '[x] foobar'
    it_behaves_like 'an invalid inapplicable task list item', 'foo [~] bar'

    it 'does not wrap a sublist with <s>' do
      doc = reference_filter(<<~MARKDOWN)
        * [~] foo _bar_ <ol><li>cursed</li></ol> **quux** xyz
      MARKDOWN

      # Non-blank text nodes should be wrapped in <s class="inapplicable">, apart from those within a sublist.
      expect(doc.to_html).to include_html('<s class="inapplicable"> foo </s><em data-sourcepos="1:11-1:15"><s class="inapplicable">bar</s></em> ')
      expect(doc.to_html).to include_html(' <strong data-sourcepos="1:42-1:49"><s class="inapplicable">quux</s></strong><s class="inapplicable"> xyz</s>')
      expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(1)
      expect(doc.css('li.inapplicable s.inapplicable').count).to eq(4)
    end

    it 'does cooperate with a following paragraph' do
      doc = reference_filter(<<~MARKDOWN)
        * [~] foo _bar_

          yay!
      MARKDOWN

      # All content is within paragraph tag; no <s class="inapplicable"> required.
      expect(doc.css('li.inapplicable s.inapplicable').count).to eq(0)
    end
  end

  it_behaves_like 'pipeline timing check'
end
