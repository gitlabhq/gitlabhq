# frozen_string_literal: true

# Shared examples to that test code that creates AwardEmoji also mark Todos
# as done.
#
# The examples expect these to be defined in the calling spec:
# - `subject` the callable code that executes the creation of an AwardEmoji
# - `user`
# - `project`
RSpec.shared_examples 'creating award emojis marks Todos as done' do
  using RSpec::Parameterized::TableSyntax

  before do
    project.add_developer(user)
  end

  where(:type, :expectation) do
    :issue           | true
    :merge_request   | true
    :project_snippet | false
  end

  with_them do
    let(:project) { awardable.project }
    let(:awardable) { create(type) }
    let!(:todo) { create(:todo, target: awardable, project: project, user: user) }

    specify do
      subject

      expect(todo.reload.done?).to eq(expectation)
    end
  end

  # Notes have more complicated rules than other Todoables
  describe 'for notes' do
    let!(:todo) { create(:todo, target: awardable.noteable, project: project, user: user) }

    context 'regular Notes' do
      let(:awardable) { create(:note, project: project) }

      it 'marks the Todo as done' do
        subject

        expect(todo.reload.done?).to eq(true)
      end
    end

    context 'PersonalSnippet Notes' do
      let(:awardable) { create(:note, noteable: create(:personal_snippet, author: user)) }

      it 'does not mark the Todo as done' do
        subject

        expect(todo.reload.done?).to eq(false)
      end
    end
  end
end
