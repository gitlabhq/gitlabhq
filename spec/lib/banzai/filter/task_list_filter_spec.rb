require 'spec_helper'

describe Banzai::Filter::TaskListFilter, lib: true do
  include FilterSpecHelper

  it 'does not apply `task-list` class to non-task lists' do
    exp = act = %(<ul><li>Item</li></ul>)
    expect(filter(act).to_html).to eq exp
  end

  it 'applies `task-list` to single-item task lists' do
    act = filter('<ul><li>[ ] Task 1</li></ul>')

    expect(act.to_html).to start_with '<ul class="task-list">'
  end
end
