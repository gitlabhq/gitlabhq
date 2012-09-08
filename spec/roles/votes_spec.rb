require 'spec_helper'

describe Issue, "Upvote" do
  let(:issue) { create(:issue) }

  it "with no notes has a 0/0 score" do
    issue.upvotes.should == 0
  end

  it "should recognize non-+1 notes" do
    issue.notes << create(:note, note: "No +1 here")
    issue.should have(1).note
    issue.notes.first.upvote?.should be_false
    issue.upvotes.should == 0
  end

  it "should recognize a single +1 note" do
    issue.notes << create(:note, note: "+1 This is awesome")
    issue.upvotes.should == 1
  end

  it "should recognize multiple +1 notes" do
    issue.notes << create(:note, note: "+1 This is awesome")
    issue.notes << create(:note, note: "+1 I want this")
    issue.upvotes.should == 2
  end
end
