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

    # Note the data-checkbox-sourcepos has changed, since the 'x' is one byte wide.
    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="13:4-13:4"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
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

    # Note that, as an imprecise sourcepos was used, the data-checkbox-sourcepos has
    # not changed. Imprecise sourcepos is only used when there is a maximum of a single
    # task item on any given line, so no special care is needed -- future partial updates
    # will also use imprecise sourcepos.
    checkbox = toggler_updated_fragment(toggler).css(
      'input.task-list-item-checkbox[data-checkbox-sourcepos="13:4-13:5"]').first
    expect(checkbox['checked']).not_to be_nil
    expect(checkbox['disabled']).not_to be_nil
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

  context 'with tables' do
    let(:markdown) do
      <<~EOT
        A delicious table awaits:

        | omg | no way | for me?? |
        | --- | ------ | -------- |
        | [ ] | [x]    | [ ] |
        |    [~] |   [ ] |    [x] |

        They might be embedded in any kind of syntax.

        > 3. Ordered list in blockquote ...
        > 4. [ ] With a task item.
        >
        >    And a table inside that task item, with a no-break space:
        >
        >    | wow | woah | how? | guau  |
        >    | --- | ---- | ---- | ----: |
        >    | [x] | [ ]  | [ ]  |   [ ] |

        Shrimple.
      EOT
    end

    it 'toggles precisely what is asked for' do
      toggler = described_class.new(
        markdown,
        markdown_html,
        toggle_as_checked: true,
        line_source: '|    [~] |   [ ] |    [x] |',
        line_sourcepos: '6:15-6:15'
      )

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[5]).to eq "|    [~] |   [x] |    [x] |\n"

      # Assert that the targetted checkbox was indeed in exactly the table, row and cell we expect.
      checkbox = toggler_updated_fragment(toggler).xpath(
        '(((.//table)[1]//tr)[3]/td)[2]/input[@data-checkbox-sourcepos="6:15-6:15"]').first
      expect(checkbox['checked']).not_to be_nil
      expect(checkbox['disabled']).not_to be_nil
    end

    it 'handles nested block elements and no-break spaces' do
      toggler = described_class.new(
        markdown,
        markdown_html,
        toggle_as_checked: true,
        line_source: '>    | [x] | [ ]  | [ ]  |   [ ] |',
        line_sourcepos: '17:15-17:16'
      )

      expect(toggler.execute).to be_truthy
      expect(toggler.updated_markdown.lines[16]).to eq ">    | [x] | [x]  | [ ]  |   [ ] |\n"

      # Assert that the checkbox sourcepos has been updated (was two bytes, now one),
      # and that the subsequent checkboxes' sourcepos have also been adjusted backwards.
      # Likewise assert the preceding checkbox's sourcepos has not been modified.

      checkboxes = toggler_updated_fragment(toggler).xpath(
        '((.//table)[2]//tr)[2]/td').map { |td| td.css('input.task-list-item-checkbox').first }
      expect(checkboxes.length).to eq(4)

      expect(checkboxes[0]['data-checkbox-sourcepos']).to eq('17:9-17:9')
      expect(checkboxes[0]['checked']).not_to be_nil
      expect(checkboxes[0]['disabled']).not_to be_nil

      expect(checkboxes[1]['data-checkbox-sourcepos']).to eq('17:15-17:15')
      expect(checkboxes[1]['checked']).not_to be_nil
      expect(checkboxes[1]['disabled']).not_to be_nil

      expect(checkboxes[2]['data-checkbox-sourcepos']).to eq('17:22-17:22')
      expect(checkboxes[2]['checked']).to be_nil
      expect(checkboxes[2]['disabled']).not_to be_nil

      expect(checkboxes[3]['data-checkbox-sourcepos']).to eq('17:31-17:32')
      expect(checkboxes[3]['checked']).to be_nil
      expect(checkboxes[3]['disabled']).not_to be_nil
    end

    context 'when a multi-byte character precedes the checkbox on the same line' do
      let(:markdown) do
        <<~EOT
          | 🐰 | [ ] | [ ] |
          | -- | --- | --- |
        EOT
      end

      it 'correctly locates and modifies the target checkbox' do
        # rubocop:disable Style/AsciiComments -- Unicode handling discussion.
        #
        # Sourcepos is byte-based. '🐰' is 4 bytes in UTF-8 (0xF0 0x9F 0x90 0xB0), so:
        #
        #         11    17
        # | 🐰 | [ ] | [ ] |
        # 123…78911111111112
        #        01234567890
        #
        # The first checkbox's symbol is at 1:11, and the second's is at 1:17.
        #
        # rubocop:enable Style/AsciiComments

        toggler = described_class.new(
          markdown,
          markdown_html,
          toggle_as_checked: true,
          line_source: '| 🐰 | [ ] | [ ] |',
          line_sourcepos: '1:17-1:17'
        )

        expect(toggler.execute).to be_truthy
        expect(toggler.updated_markdown.lines[0]).to eq "| 🐰 | [ ] | [x] |\n"
      end
    end
  end

  describe '.adjust_sourcepos' do
    let(:sourcepos) { { start: { line: 10, column: 5 }, end: { line: 10, column: 8 } } }

    it 'adjusts all positions' do
      result = described_class.adjust_sourcepos(
        sourcepos,
        start: { line: 1, column: 2 },
        end: { line: 3, column: -4 }
      )

      expect(result).to eq({ start: { line: 11, column: 7 }, end: { line: 13, column: 4 } })
    end

    it 'returns the input unchanged when no adjustments are made' do
      result = described_class.adjust_sourcepos(sourcepos)

      expect(result).to eq(sourcepos)
    end
  end

  def parse_markdown(markdown)
    Banzai::Pipeline::FullPipeline.call(markdown, project: nil)[:output].to_html
  end

  def toggler_updated_fragment(toggler)
    Nokogiri::HTML.fragment(toggler.updated_markdown_html)
  end
end
