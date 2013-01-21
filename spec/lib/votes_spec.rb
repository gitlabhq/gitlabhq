require 'spec_helper'

describe MergeRequest do
  let(:merge_request) { FactoryGirl.create(:merge_request_with_diffs) }

  describe "#upvotes" do
    it "with no notes has a 0/0 score" do
      merge_request.upvotes.should == 0
    end

    it "should recognize non-+1 notes" do
      merge_request.notes << create(:note, note: "No +1 here")
      merge_request.should have(1).note
      merge_request.notes.first.upvote?.should be_false
      merge_request.upvotes.should == 0
    end

    it "should recognize a single +1 note" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.upvotes.should == 1
    end

    it "should recognize multiple +1 notes" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.notes << create(:note, note: "+1 I want this")
      merge_request.upvotes.should == 2
    end
  end

  describe "#downvotes" do
    it "with no notes has a 0/0 score" do
      merge_request.downvotes.should == 0
    end

    it "should recognize non--1 notes" do
      merge_request.notes << create(:note, note: "Almost got a -1")
      merge_request.should have(1).note
      merge_request.notes.first.downvote?.should be_false
      merge_request.downvotes.should == 0
    end

    it "should recognize a single -1 note" do
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.downvotes.should == 1
    end

    it "should recognize multiple -1 notes" do
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.notes << create(:note, note: "-1 Away with this")
      merge_request.downvotes.should == 2
    end
  end

  describe "#votes_count" do
    it "with no notes has a 0/0 score" do
      merge_request.votes_count.should == 0
    end

    it "should recognize non notes" do
      merge_request.notes << create(:note, note: "No +1 here")
      merge_request.should have(1).note
      merge_request.votes_count.should == 0
    end

    it "should recognize a single +1 note" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.votes_count.should == 1
    end

    it "should recognize a single -1 note" do
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.votes_count.should == 1
    end

    it "should recognize multiple notes" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.notes << create(:note, note: "+1 I want this")
      merge_request.votes_count.should == 3
    end
  end

  describe "#upvotes_in_percent" do
    it "with no notes has a 0% score" do
      merge_request.upvotes_in_percent.should == 0
    end

    it "should count a single 1 note as 100%" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.upvotes_in_percent.should == 100
    end

    it "should count multiple +1 notes as 100%" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.notes << create(:note, note: "+1 I want this")
      merge_request.upvotes_in_percent.should == 100
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.notes << create(:note, note: "+1 I want this")
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.notes << create(:note, note: "+1 me too")
      merge_request.upvotes_in_percent.should == 75
    end
  end

  describe "#downvotes_in_percent" do
    it "with no notes has a 0% score" do
      merge_request.downvotes_in_percent.should == 0
    end

    it "should count a single -1 note as 100%" do
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.downvotes_in_percent.should == 100
    end

    it "should count multiple -1 notes as 100%" do
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.notes << create(:note, note: "-1 Away with this")
      merge_request.downvotes_in_percent.should == 100
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      merge_request.notes << create(:note, note: "+1 This is awesome")
      merge_request.notes << create(:note, note: "+1 I want this")
      merge_request.notes << create(:note, note: "-1 This is bad")
      merge_request.notes << create(:note, note: "+1 me too")
      merge_request.downvotes_in_percent.should == 25
    end
  end
end
