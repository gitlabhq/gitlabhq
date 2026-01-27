# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TaskListToggleService, feature_category: :markdown do
  let(:markdown) do
    <<~EOT
      * [ ] Task 1
      * [x] Task 2

      A paragraph

      1. [X] Item 1
         - [ ] Sub-item 1

      - [ ] loose list

        with an embedded paragraph

      + [ ] No-break space (U+00A0)

      2) [ ] Another item
    EOT
  end

  let(:markdown_html) do
    parse_markdown(markdown)
  end

  it 'checks Task 1 given precise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '* [ ] Task 1',
      line_sourcepos: '1:4-1:4'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "* [x] Task 1\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'li[data-sourcepos="1:1-1:12"] > input.task-list-item-checkbox').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'checks Task 1 given imprecise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '* [ ] Task 1',
      line_sourcepos: '1:1-1:12'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "* [x] Task 1\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'li[data-sourcepos="1:1-1:12"] > input.task-list-item-checkbox').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'unchecks Item 1' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: false,
      line_source: '1. [X] Item 1',
      line_sourcepos: '6:5-6:5'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[5]).to eq "1. [ ] Item 1\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="6:5-6:5"]').first
    expect(checkbox['checked']).to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'returns falsey if checking already checked' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '1. [X] Item 1',
      line_sourcepos: '6:5-6:5'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'returns falsey if unchecking already unchecked' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: false,
      line_source: '* [ ] Task 1',
      line_sourcepos: '1:4-1:4'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'checks task in loose list given precise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '- [ ] loose list',
      line_sourcepos: '9:4-9:4'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[8]).to eq "- [x] loose list\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="9:4-9:4"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'checks task in loose list given imprecise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '- [ ] loose list',
      line_sourcepos: '9:20-9:30'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[8]).to eq "- [x] loose list\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="9:4-9:4"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'checks task with no-break space given precise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '+ [ ] No-break space (U+00A0)',
      line_sourcepos: '13:4-13:5'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[12]).to eq "+ [x] No-break space (U+00A0)\n"
  end

  it 'checks task with no-break space given imprecise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '+ [ ] No-break space (U+00A0)',
      line_sourcepos: '13:1-14:0'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[12]).to eq "+ [x] No-break space (U+00A0)\n"
  end

  it 'checks Another item given precise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '2) [ ] Another item',
      line_sourcepos: '15:5-15:5'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[14]).to eq "2) [x] Another item"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="15:5-15:5"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'checks Another item given imprecise sourcepos' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: true,
      line_source: '2) [ ] Another item',
      line_sourcepos: '15:1-15:19'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[14]).to eq "2) [x] Another item"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="15:5-15:5"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it "returns falsey if the line source doesn't match" do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: false,
      line_source: '- [ ] huh?',
      line_sourcepos: '3:6-3:6'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'returns falsey if there was nothing to change' do
    toggler = described_class.new(
      markdown, markdown_html,
      toggle_as_checked: false,
      line_source: 'A paragraph',
      line_sourcepos: '4:1-4:11'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'tolerates \r\n line endings' do
    rn_markdown = markdown.gsub("\n", "\r\n")
    toggler = described_class.new(
      rn_markdown,
      markdown_html,
      toggle_as_checked: false,
      line_source: '* [x] Task 2',
      line_sourcepos: '2:1-2:12'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[1]).to eq "* [ ] Task 2\r\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="2:4-2:4"]').first
    expect(checkbox['checked']).to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'returns falsey if markdown is nil' do
    toggler = described_class.new(
      nil,
      markdown_html,
      toggle_as_checked: false,
      line_source: '* [x] Task 2',
      line_sourcepos: '2:4-2:4'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'returns falsey if markdown_html is nil' do
    toggler = described_class.new(
      markdown,
      nil,
      toggle_as_checked: false,
      line_source: '* [x] Task 2',
      line_sourcepos: '2:4-2:4'
    )

    expect(toggler.execute).to be_falsey
  end

  it 'properly handles tasks in a blockquote' do
    markdown =
      <<~EOT
        > > * [ ] Task 1
        > * [x] Task 2
      EOT

    markdown_html = parse_markdown(markdown)
    toggler = described_class.new(
      markdown,
      markdown_html,
      toggle_as_checked: true,
      line_source: '> > * [ ] Task 1',
      line_sourcepos: '1:5-1:16'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[0]).to eq "> > * [x] Task 1\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="1:8-1:8"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  it 'properly handles a GitLab blockquote' do
    markdown =
      <<~EOT
        >>>
        gitlab blockquote
        >>>

        * [ ] Task 1
        * [x] Task 2
      EOT

    markdown_html = parse_markdown(markdown)
    toggler = described_class.new(
      markdown,
      markdown_html,
      toggle_as_checked: true,
      line_source: '* [ ] Task 1',
      line_sourcepos: '5:4-5:4'
    )

    expect(toggler.execute).to be_truthy
    expect(toggler.updated_markdown.lines[4]).to eq "* [x] Task 1\n"

    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="5:4-5:4"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
  end

  context 'when clicking an embedded subtask' do
    it 'properly handles it inside an unordered list' do
      markdown =
        <<~EOT
          - - [ ] Task 1
            - [x] Task 2
        EOT

      markdown_html = parse_markdown(markdown)
      toggler = described_class.new(
        markdown,
        markdown_html,
        toggle_as_checked: true,
        line_source: '- - [ ] Task 1',
        line_sourcepos: '1:3-1:14'
      )

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[0]).to eq "- - [x] Task 1\n"

      checkbox = toggler_updated_fragment(toggler).css(
        'input.task-list-item-checkbox[data-checkbox-sourcepos="1:6-1:6"]').first
      expect(checkbox['checked']).not_to be_nil
      expect(checkbox['disabled']).not_to be_nil
    end

    it 'properly handles it inside an ordered list' do
      markdown =
        <<~EOT
          1. - [ ] Task 1
             - [x] Task 2
        EOT

      markdown_html = parse_markdown(markdown)
      toggler = described_class.new(
        markdown,
        markdown_html,
        toggle_as_checked: true,
        line_source: '1. - [ ] Task 1',
        line_sourcepos: '1:4-1:15'
      )

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[0]).to eq "1. - [x] Task 1\n"

      checkbox = toggler_updated_fragment(toggler).css(
        'input.task-list-item-checkbox[data-checkbox-sourcepos="1:7-1:7"]').first
      expect(checkbox['checked']).not_to be_nil
      expect(checkbox['disabled']).not_to be_nil
    end
  end

  def parse_markdown(markdown)
    Banzai::Pipeline::FullPipeline.call(markdown, project: nil)[:output].to_html
  end

  def toggler_updated_fragment(toggler)
    Nokogiri::HTML.fragment(toggler.updated_markdown_html)
  end
end
