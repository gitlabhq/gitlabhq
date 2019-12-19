# frozen_string_literal: true

require 'spec_helper'

describe TaskListToggleService do
  let(:markdown) do
    <<-EOT.strip_heredoc
      * [ ] Task 1
      * [x] Task 2

      A paragraph

      1. [X] Item 1
         - [ ] Sub-item 1

      - [ ] loose list

        with an embedded paragraph
    EOT
  end

  let(:markdown_html) do
    <<-EOT.strip_heredoc
      <ul data-sourcepos="1:1-3:0" class="task-list" dir="auto">
        <li data-sourcepos="1:1-1:12" class="task-list-item">
          <input type="checkbox" class="task-list-item-checkbox" disabled> Task 1
        </li>
        <li data-sourcepos="2:1-3:0" class="task-list-item">
          <input type="checkbox" class="task-list-item-checkbox" disabled checked> Task 2
        </li>
      </ul>
      <p data-sourcepos="4:1-4:11" dir="auto">A paragraph</p>
      <ol data-sourcepos="6:1-8:0" class="task-list" dir="auto">
        <li data-sourcepos="6:1-8:0" class="task-list-item">
          <input type="checkbox" class="task-list-item-checkbox" checked="" disabled=""> Item 1
          <ul data-sourcepos="7:4-8:0" class="task-list">
            <li data-sourcepos="7:4-8:0" class="task-list-item">
              <input type="checkbox" class="task-list-item-checkbox" disabled=""> Sub-item 1
            </li>
          </ul>
        </li>
      </ol>
      <ul data-sourcepos="9:1-11:28" class="task-list" dir="auto">
        <li data-sourcepos="9:1-11:28" class="task-list-item">
          <p data-sourcepos="9:3-9:16"><input type="checkbox" class="task-list-item-checkbox" disabled=""> loose list</p>
          <p data-sourcepos="11:3-11:28">with an embedded paragraph</p>
        </li>
      </ul>
    EOT
  end

  it 'checks Task 1' do
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: true,
                                  line_source: '* [ ] Task 1', line_number: 1)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "* [x] Task 1\n"
    expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
  end

  it 'unchecks Item 1' do
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: false,
                                  line_source: '1. [X] Item 1', line_number: 6)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[5]).to eq "1. [ ] Item 1\n"
    expect(toggler.updated_markdown_html).to include('disabled> Item 1')
  end

  it 'checks task in loose list' do
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: true,
                                  line_source: '- [ ] loose list', line_number: 9)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[8]).to eq "- [x] loose list\n"
    expect(toggler.updated_markdown_html).to include('disabled checked> loose list')
  end

  it 'returns false if line_source does not match the text' do
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: false,
                                  line_source: '* [x] Task Added', line_number: 2)

    expect(toggler.execute).to be_falsey
  end

  it 'tolerates \r\n line endings' do
    rn_markdown = markdown.gsub("\n", "\r\n")
    toggler = described_class.new(rn_markdown, markdown_html,
                                  toggle_as_checked: true,
                                  line_source: '* [ ] Task 1', line_number: 1)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "* [x] Task 1\r\n"
    expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
  end

  it 'returns false if markdown is nil' do
    toggler = described_class.new(nil, markdown_html,
                                  toggle_as_checked: false,
                                  line_source: '* [x] Task Added', line_number: 2)

    expect(toggler.execute).to be_falsey
  end

  it 'returns false if markdown_html is nil' do
    toggler = described_class.new(markdown, nil,
                                  toggle_as_checked: false,
                                  line_source: '* [x] Task Added', line_number: 2)

    expect(toggler.execute).to be_falsey
  end

  it 'properly handles tasks in a blockquote' do
    markdown =
      <<-EOT.strip_heredoc
      > > * [ ] Task 1
      > * [x] Task 2
    EOT

    markdown_html = parse_markdown(markdown)
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: true,
                                  line_source: '> > * [ ] Task 1', line_number: 1)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "> > * [x] Task 1\n"
    expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
  end

  it 'properly handles a GitLab blockquote' do
    markdown =
      <<-EOT.strip_heredoc
      >>>
      gitlab blockquote
      >>>

      * [ ] Task 1
      * [x] Task 2
    EOT

    markdown_html = parse_markdown(markdown)
    toggler = described_class.new(markdown, markdown_html,
                                  toggle_as_checked: true,
                                  line_source: '* [ ] Task 1', line_number: 5)

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[4]).to eq "* [x] Task 1\n"
    expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
  end

  context 'when clicking an embedded subtask' do
    it 'properly handles it inside an unordered list' do
      markdown =
        <<-EOT.strip_heredoc
      - - [ ] Task 1
        - [x] Task 2
      EOT

      markdown_html = parse_markdown(markdown)
      toggler = described_class.new(markdown, markdown_html,
                                    toggle_as_checked: true,
                                    line_source: '- - [ ] Task 1', line_number: 1)

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[0]).to eq "- - [x] Task 1\n"
      expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
    end

    it 'properly handles it inside an ordered list' do
      markdown =
        <<-EOT.strip_heredoc
      1. - [ ] Task 1
         - [x] Task 2
      EOT

      markdown_html = parse_markdown(markdown)
      toggler = described_class.new(markdown, markdown_html,
                                    toggle_as_checked: true,
                                    line_source: '1. - [ ] Task 1', line_number: 1)

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[0]).to eq "1. - [x] Task 1\n"
      expect(toggler.updated_markdown_html).to include('disabled checked> Task 1')
    end
  end

  def parse_markdown(markdown)
    Banzai::Pipeline::FullPipeline.call(markdown, project: nil)[:output].to_html
  end
end
