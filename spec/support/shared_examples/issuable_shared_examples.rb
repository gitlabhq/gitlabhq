# frozen_string_literal: true

shared_examples 'cache counters invalidator' do
  it 'invalidates counter cache for assignees' do
    expect_any_instance_of(User).to receive(:invalidate_merge_request_cache_counts)

    described_class.new(project, user, {}).execute(merge_request)
  end
end

shared_examples 'system notes for milestones' do
  def update_issuable(opts)
    issuable = try(:issue) || try(:merge_request)
    described_class.new(project, user, opts).execute(issuable)
  end

  context 'group milestones' do
    let(:group) { create(:group) }
    let(:group_milestone) { create(:milestone, group: group) }

    before do
      project.update(namespace: group)
      create(:group_member, group: group, user: user)
    end

    it 'creates a system note' do
      expect do
        update_issuable(milestone: group_milestone)
      end.to change { Note.system.count }.by(1)
    end
  end

  context 'project milestones' do
    it 'creates a system note' do
      expect do
        update_issuable(milestone: create(:milestone, project: project))
      end.to change { Note.system.count }.by(1)
    end
  end
end

shared_examples 'updating a single task' do
  def update_issuable(opts)
    issuable = try(:issue) || try(:merge_request)
    described_class.new(project, user, opts).execute(issuable)
  end

  before do
    update_issuable(description: "- [ ] Task 1\n- [ ] Task 2")
  end

  context 'when a task is marked as completed' do
    before do
      update_issuable(update_task: { index: 1, checked: true, line_source: '- [ ] Task 1', line_number: 1 })
    end

    it 'creates system note about task status change' do
      note1 = find_note('marked the task **Task 1** as completed')

      expect(note1).not_to be_nil

      description_notes = find_notes('description')
      expect(description_notes.length).to eq(1)
    end
  end

  context 'when a task is marked as incomplete' do
    before do
      update_issuable(description: "- [x] Task 1\n- [X] Task 2")
      update_issuable(update_task: { index: 2, checked: false, line_source: '- [X] Task 2', line_number: 2 })
    end

    it 'creates system note about task status change' do
      note1 = find_note('marked the task **Task 2** as incomplete')

      expect(note1).not_to be_nil

      description_notes = find_notes('description')
      expect(description_notes.length).to eq(1)
    end
  end

  context 'when the task position has been modified' do
    before do
      update_issuable(description: "- [ ] Task 1\n- [ ] Task 3\n- [ ] Task 2")
    end

    it 'raises an exception' do
      expect(Note.count).to eq(2)
      expect do
        update_issuable(update_task: { index: 2, checked: true, line_source: '- [ ] Task 2', line_number: 2 })
      end.to raise_error(ActiveRecord::StaleObjectError)
      expect(Note.count).to eq(2)
    end
  end

  context 'when the content changes but not task line number' do
    before do
      update_issuable(description: "Paragraph\n\n- [ ] Task 1\n- [x] Task 2")
      update_issuable(description: "Paragraph with more words\n\n- [ ] Task 1\n- [x] Task 2")
      update_issuable(update_task: { index: 2, checked: false, line_source: '- [x] Task 2', line_number: 4 })
    end

    it 'creates system note about task status change' do
      note1 = find_note('marked the task **Task 2** as incomplete')

      expect(note1).not_to be_nil

      description_notes = find_notes('description')
      expect(description_notes.length).to eq(2)
    end
  end
end
