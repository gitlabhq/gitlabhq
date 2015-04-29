# Specs for task state functionality for issues and merge requests.
#
# Requires a context containing:
#   subject { Issue or MergeRequest }
shared_examples 'a Taskable' do
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
    expect(subject.task_status).to match('5 tasks')
    expect(subject.task_status).to match('2 done')
    expect(subject.task_status).to match('3 unfinished')
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
