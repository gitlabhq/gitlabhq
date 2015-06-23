require 'spec_helper'

describe Issue, 'Votes' do
  let(:issue) { create(:issue) }

  describe "#upvotes" do
    it "with no notes has a 0/0 score" do
      expect(issue.upvotes).to eq(0)
    end

    it "should recognize non-+1 notes" do
      add_note "No +1 here"
      expect(issue.notes.size).to eq(1)
      expect(issue.notes.first.upvote?).to be_falsey
      expect(issue.upvotes).to eq(0)
    end

    it "should recognize a single +1 note" do
      add_note "+1 This is awesome"
      expect(issue.upvotes).to eq(1)
    end

    it 'should recognize multiple +1 notes' do
      add_note '+1 This is awesome', create(:user)
      add_note '+1 I want this', create(:user)
      expect(issue.upvotes).to eq(2)
    end

    it 'should not count 2 +1 votes from the same user' do
      add_note '+1 This is awesome'
      add_note '+1 I want this'
      expect(issue.upvotes).to eq(1)
    end
  end

  describe "#downvotes" do
    it "with no notes has a 0/0 score" do
      expect(issue.downvotes).to eq(0)
    end

    it "should recognize non--1 notes" do
      add_note "Almost got a -1"
      expect(issue.notes.size).to eq(1)
      expect(issue.notes.first.downvote?).to be_falsey
      expect(issue.downvotes).to eq(0)
    end

    it "should recognize a single -1 note" do
      add_note "-1 This is bad"
      expect(issue.downvotes).to eq(1)
    end

    it "should recognize multiple -1 notes" do
      add_note('-1 This is bad', create(:user))
      add_note('-1 Away with this', create(:user))
      expect(issue.downvotes).to eq(2)
    end
  end

  describe "#votes_count" do
    it "with no notes has a 0/0 score" do
      expect(issue.votes_count).to eq(0)
    end

    it "should recognize non notes" do
      add_note "No +1 here"
      expect(issue.notes.size).to eq(1)
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
      add_note('+1 This is awesome', create(:user))
      add_note('-1 This is bad', create(:user))
      add_note('+1 I want this', create(:user))
      expect(issue.votes_count).to eq(3)
    end

    it 'should not count 2 -1 votes from the same user' do
      add_note '-1 This is suspicious'
      add_note '-1 This is bad'
      expect(issue.votes_count).to eq(1)
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

    it 'should count multiple +1 notes as 100%' do
      add_note('+1 This is awesome', create(:user))
      add_note('+1 I want this', create(:user))
      expect(issue.upvotes_in_percent).to eq(100)
    end

    it 'should count fractions for multiple +1 and -1 notes correctly' do
      add_note('+1 This is awesome', create(:user))
      add_note('+1 I want this', create(:user))
      add_note('-1 This is bad', create(:user))
      add_note('+1 me too', create(:user))
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

    it 'should count multiple -1 notes as 100%' do
      add_note('-1 This is bad', create(:user))
      add_note('-1 Away with this', create(:user))
      expect(issue.downvotes_in_percent).to eq(100)
    end

    it 'should count fractions for multiple +1 and -1 notes correctly' do
      add_note('+1 This is awesome', create(:user))
      add_note('+1 I want this', create(:user))
      add_note('-1 This is bad', create(:user))
      add_note('+1 me too', create(:user))
      expect(issue.downvotes_in_percent).to eq(25)
    end
  end

  describe '#filter_superceded_votes' do

    it 'should count a users vote only once amongst multiple votes' do
      add_note('-1 This needs work before I will accept it')
      add_note('+1 I want this', create(:user))
      add_note('+1 This is is awesome', create(:user))
      add_note('+1 this looks good now')
      add_note('+1 This is awesome', create(:user))
      add_note('+1 me too', create(:user))
      expect(issue.downvotes).to eq(0)
      expect(issue.upvotes).to eq(5)
    end

    it 'should count each users vote only once' do
      add_note '-1 This needs work before it will be accepted'
      add_note '+1 I like this'
      add_note '+1 I still like this'
      add_note '+1 I really like this'
      add_note '+1 Give me this now!!!!'
      expect(issue.downvotes).to eq(0)
      expect(issue.upvotes).to eq(1)
    end

    it 'should count a users vote only once without caring about comments' do
      add_note '-1 This needs work before it will be accepted'
      add_note 'Comment 1'
      add_note 'Another comment'
      add_note '+1 vote'
      add_note 'final comment'
      expect(issue.downvotes).to eq(0)
      expect(issue.upvotes).to eq(1)
    end

  end

  def add_note(text, author = issue.author)
    created_at = Time.now - 1.hour + Note.count.seconds
    issue.notes << create(:note,
                          note: text,
                          project: issue.project,
                          author_id: author.id,
                          created_at: created_at)
  end
end
