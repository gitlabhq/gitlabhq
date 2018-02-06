require 'spec_helper'

describe Todo do
  let(:issue) { create(:issue) }

  describe 'relationships' do
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:note) }
    it { is_expected.to belong_to(:project) }
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

      expect(subject.target_reference).to eq commit.reference_link_text(full: true)
    end

    it 'returns full reference for issuables' do
      subject.target = issue
      expect(subject.target_reference).to eq issue.to_reference(full: true)
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

  describe '#self_assigned?' do
    let(:user_1) { build(:user) }

    before do
      subject.user = user_1
      subject.author = user_1
      subject.action = Todo::ASSIGNED
    end

    it 'is true when todo is ASSIGNED and self_added' do
      expect(subject).to be_self_assigned
    end

    it 'is false when the todo is not ASSIGNED' do
      subject.action = Todo::MENTIONED

      expect(subject).not_to be_self_assigned
    end

    it 'is false when todo is not self_added' do
      subject.author = build(:user)

      expect(subject).not_to be_self_assigned
    end
  end
end
