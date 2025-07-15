# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TaskListFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'adds `<task-button></task-button>` to every list item' do
    doc = filter("<ul data-sourcepos=\"1:1-2:20\">\n<li data-sourcepos=\"1:1-1:20\">[ ] testing item 1</li>\n<li data-sourcepos=\"2:1-2:20\">[x] testing item 2</li>\n</ul>")

    expect(doc.xpath('.//li//task-button').count).to eq(2)
  end

  it 'adds `aria-label` to every checkbox in the list' do
    doc = filter("<ul data-sourcepos=\"1:1-4:20\">\n<li data-sourcepos=\"1:1-1:20\">[ ] testing item 1</li>\n<li data-sourcepos=\"2:1-2:20\">[x] testing item 2</li>\n<li data-sourcepos=\"3:1-3:20\">[~] testing item 3</li>\n<li data-sourcepos=\"4:1-4:20\">[~] testing item 4 this is a very long label that should be truncated at some point but where does it truncate?</li>\n<li data-sourcepos=\"5:1-5:20\">[ ] <div class=\"js-snippet\" data-malacious=\"something\">suspicious item</div></li>\n<li data-sourcepos=\"6:1-6:20\">[ ] <div onclick=\"alert(0)\">suspicious item 2</div></li>\n<li data-sourcepos=\"7:1-7:20\">[~] <svg><script>&#97;lert(1)</script></svg></li>\n<li data-sourcepos=\"8:1-8:20\">[~] <svg><script>&#x61;lert(1)</script></svg></li>\n<li data-sourcepos=\"9:1-9:20\">[~] <svg><script>x=\"&quot;,alert(1)//\";</script></svg></li>\n<li data-sourcepos=\"10:1-10:20\">[~] &quot; hijacking quotes \" a \' b &apos; c</li></ul>")

    aria_labels = doc.xpath('.//li//input/@aria-label')

    expect(aria_labels.count).to eq(10)
    expect(aria_labels[0].value).to eq('Check option: testing item 1')
    expect(aria_labels[1].value).to eq('Check option: testing item 2')
    expect(aria_labels[2].value).to eq('Check option: testing item 3')
    expect(aria_labels[3].value).to eq('Check option: testing item 4 this is a very long label that should be truncated at some point but where does it…')
    expect(aria_labels[4].value).to eq('Check option: suspicious item')
    expect(aria_labels[5].value).to eq('Check option: suspicious item 2')
    expect(aria_labels[6].value).to eq('Check option: ')
    expect(aria_labels[7].value).to eq('Check option: ')
    expect(aria_labels[8].value).to eq('Check option: ')
    expect(aria_labels[9].value).to eq("Check option: \" hijacking quotes \" a ' b ' c")
  end

  it 'ignores checkbox on following line' do
    doc = filter(
      <<~HTML
        <ul data-sourcepos="1:1-3:11">
          <li data-sourcepos="1:1-3:11">one
            <ul data-sourcepos="2:3-3:11">
              <li data-sourcepos="2:3-3:11">foo
                [ ] bar</li>
            </ul>
          </li>
        </ul>
      HTML
    )

    expect(doc.xpath('.//li//input').count).to eq(0)
  end

  describe 'inapplicable list items' do
    shared_examples 'a valid inapplicable task list item' do |html|
      it "behaves correctly for `#{html}`" do
        doc = filter("<ul><li>#{html}</li></ul>")

        expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(1)
        expect(doc.css('li.inapplicable > s').count).to eq(1)
      end
    end

    shared_examples 'an invalid inapplicable task list item' do |html|
      it "does nothing for `#{html}`" do
        doc = filter("<ul><li>#{html}</li></ul>")

        expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(0)
      end
    end

    it_behaves_like 'a valid inapplicable task list item', '[~] foobar'
    it_behaves_like 'a valid inapplicable task list item', '[~] foo <em>bar</em>'
    it_behaves_like 'an invalid inapplicable task list item', '[ ] foobar'
    it_behaves_like 'an invalid inapplicable task list item', '[x] foobar'
    it_behaves_like 'an invalid inapplicable task list item', 'foo [~] bar'

    it 'does not wrap a sublist with <s>' do
      html = '[~] foo <em>bar</em>\n<ol><li>sublist</li></ol>'
      doc = filter("<ul><li>#{html}</li></ul>")

      expect(doc.to_html).to include('<s>foo <em>bar</em>\n</s>')
      expect(doc.css('li.inapplicable input[data-inapplicable]').count).to eq(1)
      expect(doc.css('li.inapplicable > s').count).to eq(1)
    end
  end

  it_behaves_like 'pipeline timing check'
end
