# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer          not null
#  target_type :string           not null
#  author_id   :integer
#  note_id     :integer
#  action      :integer
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe Task, models: true do
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
    it { is_expected.to validate_presence_of(:target) }
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '#action_name' do
    it 'returns assigned when action is assigned' do
      subject.action = Task::ASSIGNED

      expect(subject.action_name).to eq 'assigned'
    end
  end

  describe '#body?' do
    let(:issue) { build(:issue) }

    before do
      subject.target = issue
    end

    it 'returns true when target respond to title' do
      expect(subject.body?).to eq true
    end

    it 'returns false when target does not respond to title' do
      allow(issue).to receive(:respond_to?).with(:title).and_return(false)

      expect(subject.body?).to eq false
    end
  end

  describe '#note_text' do
    it 'returns nil when note is blank' do
      subject.note = nil

      expect(subject.note_text).to be_nil
    end

    it 'returns note when note is present' do
      subject.note = build(:note, note: 'quick fix')

      expect(subject.note_text).to eq 'quick fix'
    end
  end

  describe '#target_iid' do
    let(:issue) { build(:issue, id: 1, iid: 5) }

    before do
      subject.target = issue
    end

    it 'returns target.iid when target respond to iid' do
      expect(subject.target_iid).to eq 5
    end

    it 'returns target_id when target does not respond to iid' do
      allow(issue).to receive(:respond_to?).with(:iid).and_return(false)

      expect(subject.target_iid).to eq 1
    end
  end
end
