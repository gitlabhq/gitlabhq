# == Schema Information
#
# Table name: todos
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer
#  target_type :string           not null
#  author_id   :integer
#  action      :integer          not null
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#  note_id     :integer
#  commit_id   :string
#

require 'spec_helper'

describe Todo, models: true do
  let(:project) { create(:project) }
  let(:commit) { project.commit }
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
    it 'returns the short commit id for commits' do
      subject.project = project
      subject.target_type = 'Commit'
      subject.commit_id = commit.id

      expect(subject.target_reference).to eq commit.short_id
    end

    it 'returns reference for issuables' do
      subject.target = issue
      expect(subject.target_reference).to eq issue.to_reference
    end
  end
end
