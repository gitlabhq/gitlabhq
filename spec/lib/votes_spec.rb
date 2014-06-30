require 'spec_helper'

describe Issue, 'Votes' do
  let(:issue) { create(:issue) }

  describe "#upvotes" do
    it "with no notes has a 0/0 score" do
      expect(issue.upvotes).to eq(0)
    end

    it "should recognize non-+1 notes" do
      add_note "No +1 here"
      expect(issue.size).to eq(1)
      expect(issue.notes.first.upvote?).to be_false
      expect(issue.upvotes).to eq(0)
    end

    it "should recognize a single +1 note" do
      add_note "+1 This is awesome"
      expect(issue.upvotes).to eq(1)
    end

    it "should recognize multiple +1 notes" do
      add_note "+1 This is awesome"
      add_note "+1 I want this"
      expect(issue.upvotes).to eq(2)
    end
  end

  describe "#downvotes" do
    it "with no notes has a 0/0 score" do
      expect(issue.downvotes).to eq(0)
    end

    it "should recognize non--1 notes" do
      add_note "Almost got a -1"
      expect(issue.size).to eq(1)
      expect(issue.notes.first.downvote?).to be_false
      expect(issue.downvotes).to eq(0)
    end

    it "should recognize a single -1 note" do
      add_note "-1 This is bad"
      expect(issue.downvotes).to eq(1)
    end

    it "should recognize multiple -1 notes" do
      add_note "-1 This is bad"
      add_note "-1 Away with this"
      expect(issue.downvotes).to eq(2)
    end
  end

  describe "#votes_count" do
    it "with no notes has a 0/0 score" do
      expect(issue.votes_count).to eq(0)
    end

    it "should recognize non notes" do
      add_note "No +1 here"
      expect(issue.size).to eq(1)
      expect(issue.votes_count).to eq(0)
    end

    it "should recognize a single +1 note" do
      add_note "+1 This is awesome"
      expect(issue.votes_count).to eq(1)
    end

    it "should recognize a single -1 note" do
      add_note "-1 This is bad"
      expect(issue.votes_count).to eq(1)
    end

    it "should recognize multiple notes" do
      add_note "+1 This is awesome"
      add_note "-1 This is bad"
      add_note "+1 I want this"
      expect(issue.votes_count).to eq(3)
    end
  end

  describe "#upvotes_in_percent" do
    it "with no notes has a 0% score" do
      expect(issue.upvotes_in_percent).to eq(0)
    end

    it "should count a single 1 note as 100%" do
      add_note "+1 This is awesome"
      expect(issue.upvotes_in_percent).to eq(100)
    end

    it "should count multiple +1 notes as 100%" do
      add_note "+1 This is awesome"
      add_note "+1 I want this"
      expect(issue.upvotes_in_percent).to eq(100)
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      add_note "+1 This is awesome"
      add_note "+1 I want this"
      add_note "-1 This is bad"
      add_note "+1 me too"
      expect(issue.upvotes_in_percent).to eq(75)
    end
  end

  describe "#downvotes_in_percent" do
    it "with no notes has a 0% score" do
      expect(issue.downvotes_in_percent).to eq(0)
    end

    it "should count a single -1 note as 100%" do
      add_note "-1 This is bad"
      expect(issue.downvotes_in_percent).to eq(100)
    end

    it "should count multiple -1 notes as 100%" do
      add_note "-1 This is bad"
      add_note "-1 Away with this"
      expect(issue.downvotes_in_percent).to eq(100)
    end

    it "should count fractions for multiple +1 and -1 notes correctly" do
      add_note "+1 This is awesome"
      add_note "+1 I want this"
      add_note "-1 This is bad"
      add_note "+1 me too"
      expect(issue.downvotes_in_percent).to eq(25)
    end
  end

  def add_note(text)
    issue.notes << create(:note, note: text, project: issue.project)
  end
end
