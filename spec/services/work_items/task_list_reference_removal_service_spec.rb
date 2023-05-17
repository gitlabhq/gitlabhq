# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TaskListReferenceRemovalService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :repository).tap { |project| project.add_developer(developer) } }
  let_it_be(:task) { create(:work_item, project: project, title: 'Task title') }
  let_it_be(:single_line_work_item, refind: true) do
    create(:work_item, project: project, description: "- [ ] #{task.to_reference}+ single line")
  end

  let_it_be(:multiple_line_work_item, refind: true) do
    create(
      :work_item,
      project: project,
      description: <<~MARKDOWN
        Any text

        * [ ] Item to be converted
            #{task.to_reference}+ second line
            third line
        * [x] task

        More text
      MARKDOWN
    )
  end

  let(:line_number_start) { 3 }
  let(:line_number_end) { 5 }
  let(:work_item) { multiple_line_work_item }
  let(:lock_version) { work_item.lock_version }

  shared_examples 'successful work item task reference removal service' do |expected_description|
    it { is_expected.to be_success }

    it 'removes the task list item containing the task reference' do
      expect do
        result
      end.to change(work_item, :description).from(work_item.description).to(expected_description)
    end

    it 'creates system notes' do
      expect do
        result
      end.to change(Note, :count).by(1)

      expect(Note.last.note).to include('changed the description')
    end
  end

  shared_examples 'failing work item task reference removal service' do |error_message|
    it { is_expected.to be_error }

    it 'does not change the work item description' do
      expect do
        result
        work_item.reload
      end.to not_change(work_item, :description)
    end

    it 'returns an error message' do
      expect(result.errors).to contain_exactly(error_message)
    end
  end

  describe '#execute' do
    subject(:result) do
      described_class.new(
        work_item: work_item,
        task: task,
        line_number_start: line_number_start,
        line_number_end: line_number_end,
        lock_version: lock_version,
        current_user: developer
      ).execute
    end

    context 'when task mardown spans a single line' do
      let(:line_number_start) { 1 }
      let(:line_number_end) { 1 }
      let(:work_item) { single_line_work_item }

      it_behaves_like 'successful work item task reference removal service', '- [ ] Task title single line'

      context 'when description does not contain a task' do
        let_it_be(:no_matching_work_item) { create(:work_item, project: project, description: 'no matching task') }

        let(:work_item) { no_matching_work_item }

        it_behaves_like 'failing work item task reference removal service', 'Unable to detect a task on lines 1-1'
      end

      context 'when description reference does not exactly match the task reference' do
        before do
          work_item.update!(description: work_item.description.gsub(task.to_reference, "#{task.to_reference}200"))
        end

        it_behaves_like 'failing work item task reference removal service', 'Unable to detect a task on lines 1-1'
      end
    end

    context 'when task mardown spans multiple lines' do
      it_behaves_like 'successful work item task reference removal service',
        "Any text\n\n* [ ] Item to be converted\n    Task title second line\n    third line\n* [x] task\n\nMore text"
    end

    context 'when updating the work item fails' do
      before do
        work_item.title = nil
      end

      it_behaves_like 'failing work item task reference removal service', "Title can't be blank"
    end

    context 'when description is empty' do
      let_it_be(:empty_work_item) { create(:work_item, project: project, description: '') }

      let(:work_item) { empty_work_item }

      it_behaves_like 'failing work item task reference removal service', "Work item description can't be blank"
    end

    context 'when line_number_start is lower than 1' do
      let(:line_number_start) { 0 }

      it_behaves_like 'failing work item task reference removal service', 'line_number_start must be greater than 0'
    end

    context 'when line_number_end is lower than line_number_start' do
      let(:line_number_end) { line_number_start - 1 }

      it_behaves_like 'failing work item task reference removal service',
                      'line_number_end must be greater or equal to line_number_start'
    end

    context 'when lock_version is older than current' do
      let(:lock_version) { work_item.lock_version - 1 }

      it_behaves_like 'failing work item task reference removal service', 'Stale work item. Check lock version'
    end

    context 'when work item is stale before updating' do
      it_behaves_like 'failing work item task reference removal service', 'Stale work item. Check lock version' do
        before do
          ::WorkItem.where(id: work_item.id).update_all(lock_version: lock_version + 1)
        end
      end
    end
  end
end
