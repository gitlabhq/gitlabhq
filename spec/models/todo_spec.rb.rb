# == Schema Information
#
# Table name: todos
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer          not null
#  target_type :string           not null
#  author_id   :integer
#  note_id     :integer
#  action      :integer          not null
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe Todo, models: true do
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
    it 'returns proper message when action is an assigment' do
      subject.action = Todo::ASSIGNED

      expect(subject.action_name).to eq 'assigned'
    end

    it 'returns proper message when action is a mention' do
      subject.action = Todo::MENTIONED

      expect(subject.action_name).to eq 'mentioned you on'
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
