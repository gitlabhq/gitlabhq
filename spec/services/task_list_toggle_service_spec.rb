require 'spec_helper'

describe TaskListToggleService do
  context 'when ' do
    let(:markdown) do
      <<-EOT.strip_heredoc
        * [ ] Task 1
        * [x] Task 2

        A paragraph

        1. [X] Item 1
           - [ ] Sub-item 1
      EOT
    end

    let(:markdown_html) do
      <<-EOT.strip_heredoc
        <ul class="task-list" dir="auto">
          <li class="task-list-item">
            <input type="checkbox" class="task-list-item-checkbox" disabled> Task 1
          </li>
          <li class="task-list-item">
            <input type="checkbox" class="task-list-item-checkbox" disabled checked> Task 2
          </li>
        </ul>
        <p dir="auto">A paragraph</p>
        <ol class="task-list" dir="auto">
          <li class="task-list-item">
            <input type="checkbox" class="task-list-item-checkbox" disabled checked> Item 1
            <ul class="task-list">
              <li class="task-list-item">
                <input type="checkbox" class="task-list-item-checkbox" disabled> Sub-item 1
              </li>
            </ul>
          </li>
        </ol>
      EOT
    end

    it 'checks Task 1' do
      toggler = described_class.new(markdown, markdown_html,
                                    index: 1, currently_checked: false,
                                    line_source: '* [ ] Task 1', line_number: 1)

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[0]).to eq "* [x] Task 1\n"
      expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
    end

    it 'unchecks Item 1' do
      toggler = described_class.new(markdown, markdown_html,
                                    index: 3, currently_checked: true,
                                    line_source: '1. [X] Item 1', line_number: 6)

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[5]).to eq "1. [ ] Item 1\n"
      expect(toggler.updated_markdown_html).to include('disabled> Item 1')
    end

    it 'returns false if line_source does not match the text' do
      toggler = described_class.new(markdown, markdown_html,
                                    index: 2, currently_checked: true,
                                    line_source: '* [x] Task Added', line_number: 2)

      expect(toggler.execute).to be_falsey
    end

    it 'returns false if markdown is nil' do
      toggler = described_class.new(nil, markdown_html,
                                    index: 2, currently_checked: true,
                                    line_source: '* [x] Task Added', line_number: 2)

      expect(toggler.execute).to be_falsey
    end

    it 'returns false if markdown_html is nil' do
      toggler = described_class.new(markdown, nil,
                                    index: 2, currently_checked: true,
                                    line_source: '* [x] Task Added', line_number: 2)

      expect(toggler.execute).to be_falsey
    end
  end
end
