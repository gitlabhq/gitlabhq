# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todo do
  let(:issue) { create(:issue) }

  describe 'relationships' do
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:note) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:target).touch(true) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'respond to' do
    it { is_expected.to respond_to(:author_name) }
    it { is_expected.to respond_to(:author_email) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:target_type) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:author) }

    context 'for commits' do
      subject { described_class.new(target_type: 'Commit') }

      it { is_expected.to validate_presence_of(:commit_id) }
      it { is_expected.not_to validate_presence_of(:target_id) }
    end

    context 'for issuables' do
      subject { described_class.new(target: issue) }

      it { is_expected.to validate_presence_of(:target_id) }
      it { is_expected.not_to validate_presence_of(:commit_id) }
    end
  end

  describe '#body' do
    before do
      subject.target = build(:issue, title: 'Bugfix')
    end

    it 'returns target title when note is blank' do
      subject.note = nil

      expect(subject.body).to eq 'Bugfix'
    end

    it 'returns note when note is present' do
      subject.note = build(:note, note: 'quick fix')

      expect(subject.body).to eq 'quick fix'
    end
  end

  describe '#done' do
    it 'changes state to done' do
      todo = create(:todo, state: :pending)

      expect { todo.done }.to change(todo, :state).from('pending').to('done')
    end

    it 'does not raise error when is already done' do
      todo = create(:todo, state: :done)

      expect { todo.done }.not_to raise_error
    end
  end

  describe '#for_commit?' do
    it 'returns true when target is a commit' do
      subject.target_type = 'Commit'

      expect(subject.for_commit?).to eq true
    end

    it 'returns false when target is an issuable' do
      subject.target_type = 'Issue'

      expect(subject.for_commit?).to eq false
    end
  end

  describe '#for_design?' do
    it 'returns true when target is a Design' do
      subject.target_type = 'DesignManagement::Design'

      expect(subject.for_design?).to eq(true)
    end

    it 'returns false when target is not a Design' do
      subject.target_type = 'Issue'

      expect(subject.for_design?).to eq(false)
    end
  end

  describe '#for_alert?' do
    it 'returns true when target is a Alert' do
      subject.target_type = 'AlertManagement::Alert'

      expect(subject.for_alert?).to eq(true)
    end

    it 'returns false when target is not a Alert' do
      subject.target_type = 'Issue'

      expect(subject.for_alert?).to eq(false)
    end
  end

  describe '#target' do
    context 'for commits' do
      let(:project) { create(:project, :repository) }
      let(:commit) { project.commit }

      it 'returns an instance of Commit when exists' do
        subject.project = project
        subject.target_type = 'Commit'
        subject.commit_id = commit.id

        expect(subject.target).to be_a(Commit)
        expect(subject.target).to eq commit
      end

      it 'returns nil when does not exists' do
        subject.project = project
        subject.target_type = 'Commit'
        subject.commit_id = 'xxxx'

        expect(subject.target).to be_nil
      end
    end

    it 'returns the issuable for issuables' do
      subject.target_id = issue.id
      subject.target_type = issue.class.name

      expect(subject.target).to eq issue
    end
  end

  describe '#target_reference' do
    it 'returns commit full reference with short id' do
      project = create(:project, :repository)
      commit = project.commit

      subject.project = project
      subject.target_type = 'Commit'
      subject.commit_id = commit.id

      expect(subject.target_reference).to eq commit.reference_link_text(full: false)
    end

    it 'returns full reference for issuables' do
      subject.target = issue

      expect(subject.target_reference).to eq issue.to_reference(full: false)
    end
  end

  describe '#self_added?' do
    let(:user_1) { build(:user) }

    before do
      subject.user = user_1
    end

    it 'is true when the user is the author' do
      subject.author = user_1

      expect(subject).to be_self_added
    end

    it 'is false when the user is not the author' do
      subject.author = build(:user)

      expect(subject).not_to be_self_added
    end
  end

  describe '#done?' do
    let_it_be(:todo1) { create(:todo, state: :pending) }
    let_it_be(:todo2) { create(:todo, state: :done) }

    it 'returns true for todos with done state' do
      expect(todo2.done?).to be_truthy
    end

    it 'returns false for todos with state pending' do
      expect(todo1.done?).to be_falsey
    end
  end

  describe '#self_assigned?' do
    let(:user_1) { build(:user) }

    context 'when self_added' do
      before do
        subject.user = user_1
        subject.author = user_1
      end

      it 'returns true for ASSIGNED' do
        subject.action = Todo::ASSIGNED

        expect(subject).to be_self_assigned
      end

      it 'returns true for REVIEW_REQUESTED' do
        subject.action = Todo::REVIEW_REQUESTED

        expect(subject).to be_self_assigned
      end

      it 'returns false for other action' do
        subject.action = Todo::MENTIONED

        expect(subject).not_to be_self_assigned
      end
    end

    context 'when todo is not self_added' do
      before do
        subject.user = user_1
        subject.author = build(:user)
      end

      it 'returns false' do
        subject.action = Todo::ASSIGNED

        expect(subject).not_to be_self_assigned
      end
    end
  end

  describe '.for_action' do
    it 'returns the todos for a given action' do
      create(:todo, action: Todo::MENTIONED)

      todo = create(:todo, action: Todo::ASSIGNED)

      expect(described_class.for_action(Todo::ASSIGNED)).to eq([todo])
    end
  end

  describe '.for_author' do
    it 'returns the todos for a given author' do
      user1 = create(:user)
      user2 = create(:user)
      todo = create(:todo, author: user1)

      create(:todo, author: user2)

      expect(described_class.for_author(user1)).to eq([todo])
    end
  end

  describe '.for_project' do
    it 'returns the todos for a given project' do
      project1 = create(:project)
      project2 = create(:project)
      todo = create(:todo, project: project1)

      create(:todo, project: project2)

      expect(described_class.for_project(project1)).to eq([todo])
    end

    it 'returns the todos for many projects' do
      project1 = create(:project)
      project2 = create(:project)
      project3 = create(:project)

      todo1 = create(:todo, project: project1)
      todo2 = create(:todo, project: project2)
      create(:todo, project: project3)

      expect(described_class.for_project([project2, project1])).to contain_exactly(todo2, todo1)
    end
  end

  describe '.for_undeleted_projects' do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:project3) { create(:project) }

    let!(:todo1) { create(:todo, project: project1) }
    let!(:todo2) { create(:todo, project: project2) }
    let!(:todo3) { create(:todo, project: project3) }

    it 'returns the todos for a given project' do
      expect(described_class.for_undeleted_projects).to contain_exactly(todo1, todo2, todo3)
    end

    context 'when todo belongs to deleted project' do
      let(:project2) { create(:project, pending_delete: true) }

      it 'excludes todos of deleted projects' do
        expect(described_class.for_undeleted_projects).to contain_exactly(todo1, todo3)
      end
    end
  end

  describe '.for_group' do
    it 'returns the todos for a given group' do
      group1 = create(:group)
      group2 = create(:group)
      todo = create(:todo, group: group1)

      create(:todo, group: group2)

      expect(described_class.for_group(group1)).to eq([todo])
    end
  end

  describe '.for_type' do
    it 'returns the todos for a given target type' do
      todo = create(:todo, target: create(:issue))

      create(:todo, target: create(:merge_request))

      expect(described_class.for_type(Issue.name)).to eq([todo])
    end
  end

  describe '.for_target' do
    it 'returns the todos for a given target' do
      todo = create(:todo, target: create(:issue))

      create(:todo, target: create(:merge_request))

      expect(described_class.for_type(Issue.name).for_target(todo.target))
        .to contain_exactly(todo)
    end
  end

  describe '.for_commit' do
    it 'returns the todos for a commit ID' do
      todo = create(:todo, commit_id: '123')

      create(:todo, commit_id: '456')

      expect(described_class.for_commit('123')).to eq([todo])
    end
  end

  describe '.for_group_ids_and_descendants' do
    it 'returns the todos for a group and its descendants' do
      parent_group = create(:group)
      child_group = create(:group, parent: parent_group)

      todo1 = create(:todo, group: parent_group)
      todo2 = create(:todo, group: child_group)
      todos = described_class.for_group_ids_and_descendants([parent_group.id])

      expect(todos).to contain_exactly(todo1, todo2)
    end
  end

  describe '.for_user' do
    it 'returns the expected todos' do
      user1 = create(:user)
      user2 = create(:user)

      todo1 = create(:todo, user: user1)
      todo2 = create(:todo, user: user1)
      create(:todo, user: user2)

      expect(described_class.for_user(user1)).to contain_exactly(todo1, todo2)
    end
  end

  describe '.for_note' do
    it 'returns todos that belongs to notes' do
      note_1 = create(:note, noteable: issue, project: issue.project)
      note_2 = create(:note, noteable: issue, project: issue.project)
      todo_1 = create(:todo, note: note_1)
      todo_2 = create(:todo, note: note_2)
      create(:todo, note: create(:note))

      expect(described_class.for_note([note_1, note_2])).to contain_exactly(todo_1, todo_2)
    end
  end

  describe '.group_by_user_id_and_state' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    before do
      create(:todo, user: user1, state: :pending)
      create(:todo, user: user1, state: :pending)
      create(:todo, user: user1, state: :done)
      create(:todo, user: user2, state: :pending)
    end

    specify do
      expect(Todo.count_grouped_by_user_id_and_state).to eq({ [user1.id, "done"] => 1, [user1.id, "pending"] => 2, [user2.id, "pending"] => 1 })
    end
  end

  describe '.any_for_target?' do
    it 'returns true if there are todos for a given target' do
      todo = create(:todo)

      expect(described_class.any_for_target?(todo.target)).to eq(true)
    end

    it 'returns true if there is at least one todo for a given target with state pending' do
      issue = create(:issue)
      create(:todo, state: :done, target: issue)
      create(:todo, state: :pending, target: issue)

      expect(described_class.any_for_target?(issue)).to eq(true)
    end

    it 'returns false if there are only todos for a given target with state done while searching for pending' do
      issue = create(:issue)
      create(:todo, state: :done, target: issue)
      create(:todo, state: :done, target: issue)

      expect(described_class.any_for_target?(issue, :pending)).to eq(false)
    end

    it 'returns false if there are no todos for a given target' do
      issue = create(:issue)

      expect(described_class.any_for_target?(issue)).to eq(false)
    end
  end

  describe '.batch_update' do
    it 'updates the state of todos' do
      todo = create(:todo, :pending)
      ids = described_class.batch_update(state: :done)

      todo.reload

      expect(ids).to eq([todo.id])
      expect(todo.state).to eq('done')
    end

    it 'does not update todos that already have the given state' do
      create(:todo, :pending)

      expect(described_class.batch_update(state: :pending)).to be_empty
    end

    it 'updates updated_at' do
      create(:todo, :pending)

      travel_to(1.day.from_now) do
        expected_update_date = Time.current.utc

        ids = described_class.batch_update(state: :done)

        expect(Todo.where(id: ids).map(&:updated_at)).to all(be_like_time(expected_update_date))
      end
    end
  end

  describe '.distinct_user_ids' do
    subject { described_class.distinct_user_ids }

    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:todo) { create(:todo, user: user1) }
    let_it_be(:todo) { create(:todo, user: user1) }
    let_it_be(:todo) { create(:todo, user: user2) }

    it { is_expected.to contain_exactly(user1.id, user2.id) }
  end
end
