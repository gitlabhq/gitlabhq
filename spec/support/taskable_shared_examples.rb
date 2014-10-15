# Specs for task state functionality for issues and merge requests.
#
# Requires a context containing:
#   let(:subject) { Issue or MergeRequest }
shared_examples 'a Taskable' do
  before do
    subject.description = <<EOT.gsub(/ {6}/, '')
      * [ ] Task 1
      * [x] Task 2
      * [x] Task 3
      * [ ] Task 4
      * [ ] Task 5
EOT
  end

  it 'updates the Nth task correctly' do
    subject.update_nth_task(1, true)
    expect(subject.description).to match(/\[x\] Task 1/)

    subject.update_nth_task(2, true)
    expect(subject.description).to match('\[x\] Task 2')

    subject.update_nth_task(3, false)
    expect(subject.description).to match('\[ \] Task 3')

    subject.update_nth_task(4, false)
    expect(subject.description).to match('\[ \] Task 4')
  end

  it 'returns the correct task status' do
    expect(subject.task_status).to match('5 tasks')
    expect(subject.task_status).to match('2 done')
    expect(subject.task_status).to match('3 unfinished')
  end

  it 'knows if it has tasks' do
    expect(subject.tasks?).to be_true

    subject.description = 'Now I have no tasks'
    expect(subject.tasks?).to be_false
  end
end
