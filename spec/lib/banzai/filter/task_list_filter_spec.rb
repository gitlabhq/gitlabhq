# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TaskListFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'adds `<task-button></task-button>` to every list item' do
    doc = filter("<ul data-sourcepos=\"1:1-2:20\">\n<li data-sourcepos=\"1:1-1:20\">[ ] testing item 1</li>\n<li data-sourcepos=\"2:1-2:20\">[x] testing item 2</li>\n</ul>")

    expect(doc.xpath('.//li//task-button').count).to eq(2)
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
