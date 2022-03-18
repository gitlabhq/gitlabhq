# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TaskListFilter do
  include FilterSpecHelper

  it 'adds `<task-button></task-button>` to every list item' do
    doc = filter("<ul data-sourcepos=\"1:1-2:20\">\n<li data-sourcepos=\"1:1-1:20\">[ ] testing item 1</li>\n<li data-sourcepos=\"2:1-2:20\">[x] testing item 2</li>\n</ul>")

    expect(doc.xpath('.//li//task-button').count).to eq(2)
  end
end
