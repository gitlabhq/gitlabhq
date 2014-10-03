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

  describe 'assignment' do
    subject { create(:issue) }

    context 'without an assignee' do
      it 'can be created' do
        subject.assignee = nil
        expect(subject.valid?).to be_true
      end
    end

    context 'with an assignee without permissions on the project' do
      it 'cannot assign the issue' do
        subject.project = create(:project)
        subject.assignee = create(:user)
        expect(subject.valid?).to be_false
      end
    end

    context 'with an assignee with permissions on the project' do
      let(:user) { create(:user) }
      let(:project) do
        p = create(:project)
        p.team.add_user(user, Gitlab::Access::DEVELOPER)
        p
      end
      let(:issue) { create(:issue, project: project) }

      it 'can assign the issue' do
        issue.assignee = user
        expect(issue.valid?).to be_true
      end

      describe '#is_being_reassigned?' do
        it 'returns true if the issue assignee has changed' do
          issue.assignee = user
          expect(issue.is_being_reassigned?).to be_true
        end
        it 'returns false if the issue assignee has not changed' do
          expect(issue.is_being_reassigned?).to be_false
        end
      end

      describe '#is_being_reassigned?' do
        it 'returns issues assigned to user' do

          2.times do
            issue = create :issue, project: project, assignee: user
          end

          expect(Issue.open_for(user).count).to eq 2
        end
      end

    end
  end

  it_behaves_like 'an editable mentionable' do
    let(:subject) { create :issue, project: mproject }
    let(:backref_text) { "issue ##{subject.iid}" }
    let(:set_mentionable_text) { ->(txt){ subject.description = txt } }
  end
end
