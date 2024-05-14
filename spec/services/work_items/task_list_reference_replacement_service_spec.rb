# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TaskListReferenceReplacementService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: developer) }
  let_it_be(:single_line_work_item, refind: true) { create(:work_item, project: project, description: '- [ ] single line', lock_version: 3) }
  let_it_be(:multiple_line_work_item, refind: true) { create(:work_item, project: project, description: "Any text\n\n* [ ] Item to be converted\n    second line\n    third line", lock_version: 3) }

  let(:line_number_start) { 3 }
  let(:line_number_end) { 5 }
  let(:title) { 'work item title' }
  let(:reference) { 'any reference' }
  let(:work_item) { multiple_line_work_item }
  let(:lock_version) { 3 }
  let(:expected_additional_text) { '' }

  shared_examples 'successful work item task reference replacement service' do
    it { is_expected.to be_success }

    it 'replaces the original issue markdown description with new work item reference' do
      result

      expect(work_item.description).to eq("#{expected_additional_text}#{task_prefix} #{reference}+")
    end
  end

  shared_examples 'failing work item task reference replacement service' do |error_message|
    it { is_expected.to be_error }

    it 'returns an error message' do
      expect(result.errors).to contain_exactly(error_message)
    end
  end

  describe '#execute' do
    subject(:result) do
      described_class.new(
        work_item: work_item,
        current_user: developer,
        work_item_reference: reference,
        line_number_start: line_number_start,
        line_number_end: line_number_end,
        title: title,
        lock_version: lock_version
      ).execute
    end

    context 'when task mardown spans a single line' do
      let(:line_number_start) { 1 }
      let(:line_number_end) { 1 }
      let(:work_item) { single_line_work_item }
      let(:task_prefix) { '- [ ]' }

      it_behaves_like 'successful work item task reference replacement service'

      it 'creates description version note' do
        expect { result }.to change(Note, :count).by(1)
        expect(work_item.notes.last.note).to eq('changed the description')
        expect(work_item.saved_description_version.id).to eq(work_item.notes.last.system_note_metadata.description_version_id)
      end
    end

    context 'when task mardown spans multiple lines' do
      let(:task_prefix) { '* [ ]' }
      let(:expected_additional_text) { "Any text\n\n" }

      it_behaves_like 'successful work item task reference replacement service'
    end

    context 'when description does not contain a task' do
      let_it_be(:no_matching_work_item) { create(:work_item, project: project, description: 'no matching task') }

      let(:work_item) { no_matching_work_item }

      it_behaves_like 'failing work item task reference replacement service', 'Unable to detect a task on line 3'
    end

    context 'when description is empty' do
      let_it_be(:empty_work_item) { create(:work_item, project: project, description: '') }

      let(:work_item) { empty_work_item }

      it_behaves_like 'failing work item task reference replacement service', "Work item description can't be blank"
    end

    context 'when line_number_start is lower than 1' do
      let(:line_number_start) { 0 }

      it_behaves_like 'failing work item task reference replacement service', 'line_number_start must be greater than 0'
    end

    context 'when line_number_end is lower than line_number_start' do
      let(:line_number_end) { line_number_start - 1 }

      it_behaves_like 'failing work item task reference replacement service', 'line_number_end must be greater or equal to line_number_start'
    end

    context 'when lock_version is older than current' do
      let(:lock_version) { 2 }

      it_behaves_like 'failing work item task reference replacement service', 'Stale work item. Check lock version'
    end

    context 'when work item is stale before updating' do
      it_behaves_like 'failing work item task reference replacement service', 'Stale work item. Check lock version' do
        before do
          ::WorkItem.where(id: work_item.id).update_all(lock_version: lock_version + 1)
        end
      end
    end
  end
end
