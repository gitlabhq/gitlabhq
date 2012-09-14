require 'spec_helper'

describe Issue do
  let(:issue) { create(:issue) }

  describe "#upvotes" do
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

  describe "#downvotes" do
    it "with no notes has a 0/0 score" do
      issue.downvotes.should == 0
    end

    it "should recognize non--1 notes" do
      issue.notes << create(:note, note: "Almost got a -1")
      issue.should have(1).note
      issue.notes.first.downvote?.should be_false
      issue.downvotes.should == 0
    end

    it "should recognize a single -1 note" do
      issue.notes << create(:note, note: "-1 This is bad")
      issue.downvotes.should == 1
    end

    it "should recognize multiple -1 notes" do
      issue.notes << create(:note, note: "-1 This is bad")
      issue.notes << create(:note, note: "-1 Away with this")
      issue.downvotes.should == 2
    end
  end

  describe "#votes_count" do
    it "with no notes has a 0/0 score" do
      issue.votes_count.should == 0
    end

    it "should recognize non notes" do
      issue.notes << create(:note, note: "No +1 here")
      issue.should have(1).note
      issue.votes_count.should == 0
    end

    it "should recognize a single +1 note" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.votes_count.should == 1
    end

    it "should recognize a single -1 note" do
      issue.notes << create(:note, note: "-1 This is bad")
      issue.votes_count.should == 1
    end

    it "should recognize multiple notes" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.notes << create(:note, note: "-1 This is bad")
      issue.notes << create(:note, note: "+1 I want this")
      issue.votes_count.should == 3
    end
  end

  describe "#upvotes_in_percent" do
    it "with no notes has a 0% score" do
      issue.upvotes_in_percent.should == 0
    end

    it "should count a single 1 note as 100%" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.upvotes_in_percent.should == 100
    end

    it "should count multiple +1 notes as 100%" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.notes << create(:note, note: "+1 I want this")
      issue.upvotes_in_percent.should == 100
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.notes << create(:note, note: "+1 I want this")
      issue.notes << create(:note, note: "-1 This is bad")
      issue.notes << create(:note, note: "+1 me too")
      issue.upvotes_in_percent.should == 75
    end
  end

  describe "#downvotes_in_percent" do
    it "with no notes has a 0% score" do
      issue.downvotes_in_percent.should == 0
    end

    it "should count a single -1 note as 100%" do
      issue.notes << create(:note, note: "-1 This is bad")
      issue.downvotes_in_percent.should == 100
    end

    it "should count multiple -1 notes as 100%" do
      issue.notes << create(:note, note: "-1 This is bad")
      issue.notes << create(:note, note: "-1 Away with this")
      issue.downvotes_in_percent.should == 100
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      issue.notes << create(:note, note: "+1 This is awesome")
      issue.notes << create(:note, note: "+1 I want this")
      issue.notes << create(:note, note: "-1 This is bad")
      issue.notes << create(:note, note: "+1 me too")
      issue.downvotes_in_percent.should == 25
    end
  end
end
