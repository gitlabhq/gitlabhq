require 'spec_helper'

module Gitlab::Markdown
  describe TaskListFilter do
    def filter(html, options = {})
      described_class.call(html, options)
    end

    it 'does not apply `task-list` class to non-task lists' do
      exp = act = %(<ul><li>Item</li></ul>)
      expect(filter(act).to_html).to eq exp
    end
  end
end
