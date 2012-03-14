require 'spec_helper'

describe MergeRequest do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:author) }
    it { should belong_to(:assignee) }
  end

  describe "Validation" do
    it { should validate_presence_of(:target_branch) }
    it { should validate_presence_of(:source_branch) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author_id) }
    it { should validate_presence_of(:project_id) }
    it { should validate_presence_of(:assignee_id) }
  end

  describe "Scope" do
    it { MergeRequest.should respond_to :closed }
    it { MergeRequest.should respond_to :opened }
  end

  it { Factory.create(:merge_request,
                      :author => Factory(:user),
                      :assignee => Factory(:user),
                      :project => Factory.create(:project)).should be_valid }

  describe "plus 1" do
    let(:project) { Factory(:project) }
    subject {
      Factory.create(:merge_request,
                     :author => Factory(:user),
                     :assignee => Factory(:user),
                     :project => project)
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
end
# == Schema Information
#
# Table name: merge_requests
#
#  id            :integer         not null, primary key
#  target_branch :string(255)     not null
#  source_branch :string(255)     not null
#  project_id    :integer         not null
#  author_id     :integer
#  assignee_id   :integer
#  title         :string(255)
#  closed        :boolean         default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

