# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Taskable, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  describe '.get_tasks' do
    let(:description) do
      <<~MARKDOWN
        Any text before the list
        - [ ] First item
        - [x] Second item
        * [x] Third item
        * [ ] Fourth item
        * [~] Inapplicable item

        <!-- a comment
        - [ ] Item in comment, ignore
         rest of comment -->

        + [ ] No-break space (U+00A0)
        + [ ] Figure space (U+2007)

        ```
        - [ ] Item in code, ignore
        ```

        + [ ] Narrow no-break space (U+202F)
        + [ ] Thin space (U+2009)

        1. [ ] Numbered 1
        2) [x] Numbered 2
      MARKDOWN
    end

    let(:expected_result) do
      [
        Taskable::Item.new(false, 'First item', ' First item'),
        Taskable::Item.new(true, 'Second item', ' Second item'),
        Taskable::Item.new(true, 'Third item', ' Third item'),
        Taskable::Item.new(false, 'Fourth item', ' Fourth item'),
        Taskable::Item.new(false, 'No-break space (U+00A0)', ' No-break space (U+00A0)'),
        Taskable::Item.new(false, 'Figure space (U+2007)', ' Figure space (U+2007)'),
        Taskable::Item.new(false, 'Narrow no-break space (U+202F)', ' Narrow no-break space (U+202F)'),
        Taskable::Item.new(false, 'Thin space (U+2009)', ' Thin space (U+2009)'),
        Taskable::Item.new(false, 'Numbered 1', ' Numbered 1'),
        Taskable::Item.new(true, 'Numbered 2', ' Numbered 2')
      ]
    end

    subject { described_class.get_tasks(description) }

    it { is_expected.to match(expected_result) }

    describe 'with single line comments' do
      let(:description) do
        <<~MARKDOWN
          <!-- line comment -->

          - [ ] only task item

          <!-- another line comment -->
        MARKDOWN
      end

      let(:expected_result) { [Taskable::Item.new(false, 'only task item', ' only task item')] }

      it { is_expected.to match(expected_result) }
    end
  end

  describe '.get_updated_tasks' do
    subject(:updated_tasks) { described_class.get_updated_tasks(old_content:, new_content:) }

    let(:old_content) do
      <<~MARKDOWN
        Hello, world.

        - [x] Do this.
        - [ ] And that.
      MARKDOWN
    end

    shared_examples_for 'get_updated_tasks' do |expected|
      it "reports #{expected.length} changed task(s)" do
        expect(updated_tasks).to eq(expected)
      end
    end

    context 'when no tasks have changed' do
      # The body content changes here, but the tasks haven't changed.
      let(:new_content) do
        <<~MARKDOWN
          Hi, world!

          - [x] Do this.
          - [ ] And that.
          - [ ]
        MARKDOWN
      end

      it_behaves_like 'get_updated_tasks', []
    end

    context 'when tasks have changed status, and one has changed text' do
      let(:new_content) do
        <<~MARKDOWN
          Hello, world.

          - [x] Do the other.
          - [x] And that.
        MARKDOWN
      end

      # We don't report on tasks being added, removed, or 'edited' --- only
      # when an existing task's completed status is changed without other modifications.
      # If the task's index is changed, we won't recognise it.
      # Ideally the frontend only sends single task updates at a time, so we mostly
      # don't deal with that situation.
      it_behaves_like 'get_updated_tasks', [Taskable::Item.new(true, 'And that.', ' And that.')]
    end
  end

  describe '#task_list_items' do
    where(issuable_type: [:issue, :merge_request])

    with_them do
      let(:issuable) { build(issuable_type, description: description) }

      subject(:result) { issuable.task_list_items }

      context 'when description is present' do
        let(:description) { 'markdown' }

        it 'gets tasks from markdown' do
          expect(described_class).to receive(:get_tasks)

          result
        end
      end

      context 'when description is blank' do
        let(:description) { '' }

        it 'returns empty array' do
          expect(result).to be_empty
        end

        it 'does not try to get tasks from markdown' do
          expect(described_class).not_to receive(:get_tasks)

          result
        end
      end
    end
  end
end
