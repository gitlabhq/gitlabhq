# frozen_string_literal: true

# Specs for task state functionality for issues and merge requests.
#
# Requires a context containing:
#   subject { Issue or MergeRequest }
RSpec.shared_examples 'a Taskable' do
  describe 'with multiple tasks' do
    before do
      subject.description = <<-EOT.strip_heredoc
        * [ ] Task 1
        * [x] Task 2
        * [x] Task 3
        * [ ] Task 4
        * [ ] Task 5
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('2 of')
      expect(subject.task_status).to match('5 checklist items completed')
      expect(subject.task_status_short).to match('2/')
      expect(subject.task_status_short).to match('5 checklist items')
    end

    describe '#tasks?' do
      it 'returns true when object has tasks' do
        expect(subject.tasks?).to eq true
      end

      it 'returns false when object has no tasks' do
        subject.description = 'Now I have no tasks'
        expect(subject.tasks?).to eq false
      end
    end
  end

  describe 'with nested tasks' do
    before do
      subject.description = <<-EOT.strip_heredoc
        - [ ] Task a
          - [x] Task a.1
          - [ ] Task a.2
        - [ ] Task b

        1. [ ] Task 1
          1. [ ] Task 1.1
          1. [ ] Task 1.2
        1. [x] Task 2
          1. [x] Task 2.1
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('3 of')
      expect(subject.task_status).to match('9 checklist items completed')
      expect(subject.task_status_short).to match('3/')
      expect(subject.task_status_short).to match('9 checklist items')
    end
  end

  describe 'with an incomplete task' do
    before do
      subject.description = <<-EOT.strip_heredoc
        * [ ] Task 1
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('0 of')
      expect(subject.task_status).to match('1 checklist item completed')
      expect(subject.task_status_short).to match('0/')
      expect(subject.task_status_short).to match('1 checklist item')
    end
  end

  describe 'with tasks that are not formatted correctly' do
    before do
      subject.description = <<-EOT.strip_heredoc
        [ ] task 1
        [ ] task 2

        - [ ]task 1
        -[ ] task 2
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('0 of')
      expect(subject.task_status).to match('0 checklist items completed')
      expect(subject.task_status_short).to match('0/')
      expect(subject.task_status_short).to match('0 checklist items')
    end
  end

  describe 'with a complete task' do
    before do
      subject.description = <<-EOT.strip_heredoc
        * [x] Task 1
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('1 of')
      expect(subject.task_status).to match('1 checklist item completed')
      expect(subject.task_status_short).to match('1/')
      expect(subject.task_status_short).to match('1 checklist item')
    end
  end

  describe 'with tasks in blockquotes' do
    before do
      subject.description = <<-EOT.strip_heredoc
        > - [ ] Task a
        > > - [x] Task a.1

        >>>
        1. [ ] Task 1
        1. [x] Task 2
        >>>
      EOT
    end

    it 'returns the correct task status' do
      expect(subject.task_status).to match('2 of')
      expect(subject.task_status).to match('4 checklist items completed')
      expect(subject.task_status_short).to match('2/')
      expect(subject.task_status_short).to match('4 checklist items')
    end
  end
end
