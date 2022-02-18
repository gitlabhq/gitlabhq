# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Taskable do
  using RSpec::Parameterized::TableSyntax

  describe '.get_tasks' do
    let(:description) do
      <<~MARKDOWN
        Any text before the list
        - [ ] First item
        - [x] Second item
        * [x] First item
        * [ ] Second item
      MARKDOWN
    end

    let(:expected_result) do
      [
        TaskList::Item.new('- [ ]', 'First item'),
        TaskList::Item.new('- [x]', 'Second item'),
        TaskList::Item.new('* [x]', 'First item'),
        TaskList::Item.new('* [ ]', 'Second item')
      ]
    end

    subject { described_class.get_tasks(description) }

    it { is_expected.to match(expected_result) }
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
