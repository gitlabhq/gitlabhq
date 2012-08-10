require 'spec_helper'

describe Issue do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
    it { should belong_to(:milestone) }
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
  end

  describe "Scope" do
    it { Issue.should respond_to :closed }
    it { Issue.should respond_to :opened }
  end

  subject { Factory.create(:issue,
                           author: Factory(:user),
                           assignee: Factory(:user),
                           project: Factory.create(:project)) }
  it { should be_valid }

  describe '#is_being_reassigned?' do
    it 'returns true if the issue assignee has changed' do
      subject.assignee = Factory(:user)
      subject.is_being_reassigned?.should be_true
    end
    it 'returns false if the issue assignee has not changed' do
      subject.is_being_reassigned?.should be_false
    end
  end

  describe '#is_being_closed?' do
    it 'returns true if the closed attribute has changed and is now true' do
      subject.closed = true
      subject.is_being_closed?.should be_true
    end
    it 'returns false if the closed attribute has changed and is now false' do
      issue = Factory.create(:issue,
                             closed: true,
                             author: Factory(:user),
                             assignee: Factory(:user),
                             project: Factory.create(:project))
      issue.closed = false
      issue.is_being_closed?.should be_false
    end
    it 'returns false if the closed attribute has not changed' do
      subject.is_being_closed?.should be_false
    end
  end


  describe '#is_being_reopened?' do
    it 'returns true if the closed attribute has changed and is now false' do
      issue = Factory.create(:issue,
                             closed: true,
                             author: Factory(:user),
                             assignee: Factory(:user),
                             project: Factory.create(:project))
      issue.closed = false
      issue.is_being_reopened?.should be_true
    end
    it 'returns false if the closed attribute has changed and is now true' do
      subject.closed = true
      subject.is_being_reopened?.should be_false
    end
    it 'returns false if the closed attribute has not changed' do
      subject.is_being_reopened?.should be_false
    end
  end

  describe "plus 1" do
    let(:project) { Factory(:project) }
    subject {
      Factory.create(:issue,
                     author: Factory(:user),
                     assignee: Factory(:user),
                     project: project)
    }

    it "with no notes has a 0/0 score" do
      subject.upvotes.should == 0
    end

    it "should recognize non-+1 notes" do
      subject.notes << Factory(:note, note: "No +1 here", project: Factory(:project, path: 'plusone', code: 'plusone'))
      subject.should have(1).note
      subject.notes.first.upvote?.should be_false
      subject.upvotes.should == 0
    end

    it "should recognize a single +1 note" do
      subject.notes << Factory(:note, note: "+1 This is awesome", project: Factory(:project, path: 'plusone', code: 'plusone'))
      subject.upvotes.should == 1
    end

    it "should recognize a multiple +1 notes" do
      subject.notes << Factory(:note, note: "+1 This is awesome", project: Factory(:project, path: 'plusone', code: 'plusone'))
      subject.notes << Factory(:note, note: "+1 I want this", project: Factory(:project, path: 'plustwo', code: 'plustwo'))
      subject.upvotes.should == 2
    end
  end

  describe ".search" do
    let!(:issue) { Factory.create(:issue, title: "Searchable issue",
                                 project: Factory.create(:project)) }

    it "matches by title" do
      Issue.search('able').all.should == [issue]
    end
  end
end
# == Schema Information
#
# Table name: issues
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  assignee_id  :integer(4)
#  author_id    :integer(4)
#  project_id   :integer(4)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  closed       :boolean(1)      default(FALSE), not null
#  position     :integer(4)      default(0)
#  critical     :boolean(1)      default(FALSE), not null
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer(4)
#

