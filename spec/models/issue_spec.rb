# == Schema Information
#
# Table name: issues
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  assignee_id  :integer
#  author_id    :integer
#  project_id   :integer
#  created_at   :datetime
#  updated_at   :datetime
#  position     :integer          default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#  state        :string(255)
#  iid          :integer
#

require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { should belong_to(:milestone) }
  end

  describe "Mass assignment" do
  end

  describe 'modules' do
    it { should include_module(Issuable) }
  end

  subject { create(:issue) }

  describe '#is_being_reassigned?' do
    it 'returns true if the issue assignee has changed' do
      subject.assignee = create(:user)
      subject.is_being_reassigned?.should be_true
    end
    it 'returns false if the issue assignee has not changed' do
      subject.is_being_reassigned?.should be_false
    end
  end

  describe '#is_being_reassigned?' do
    it 'returns issues assigned to user' do
      user = create :user

      2.times do
        issue = create :issue, assignee: user
      end

      Issue.open_for(user).count.should eq 2
    end
  end

  it_behaves_like 'an editable mentionable' do
    let(:subject) { create :issue, project: mproject }
    let(:backref_text) { "issue ##{subject.iid}" }
    let(:set_mentionable_text) { ->(txt){ subject.description = txt } }
  end
end
