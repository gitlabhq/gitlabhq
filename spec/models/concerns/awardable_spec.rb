require 'spec_helper'

describe Awardable do
  let!(:issue)        { create(:issue) }
  let!(:award_emoji)  { create(:award_emoji, :downvote, awardable: issue) }

  describe "Associations" do
    subject { build(:issue) }

    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
  end

  describe "ClassMethods" do
    let!(:issue2) { create(:issue) }
    let!(:award_emoji2) { create(:award_emoji, awardable: issue2) }

    describe "orders" do
      it "orders on upvotes" do
        expect(Issue.order_upvotes_desc.to_a).to eq [issue2, issue]
      end

      it "orders on downvotes" do
        expect(Issue.order_downvotes_desc.to_a).to eq [issue, issue2]
      end
    end

    describe ".awarded" do
      it "filters by user and emoji name" do
        expect(Issue.awarded(award_emoji.user, "thumbsup")).to be_empty
        expect(Issue.awarded(award_emoji.user, "thumbsdown")).to eq [issue]
        expect(Issue.awarded(award_emoji2.user, "thumbsup")).to eq [issue2]
        expect(Issue.awarded(award_emoji2.user, "thumbsdown")).to be_empty
      end
    end
  end

  describe "#upvotes" do
    it "counts the number of upvotes" do
      expect(issue.upvotes).to be 0
    end
  end

  describe "#downvotes" do
    it "counts the number of downvotes" do
      expect(issue.downvotes).to be 1
    end
  end

  describe "#toggle_award_emoji" do
    it "adds an emoji if it isn't awarded yet" do
      expect { issue.toggle_award_emoji("thumbsup", award_emoji.user) }.to change { AwardEmoji.count }.by(1)
    end

    it "toggles already awarded emoji" do
      expect { issue.toggle_award_emoji("thumbsdown", award_emoji.user) }.to change { AwardEmoji.count }.by(-1)
    end
  end

  describe 'querying award_emoji on an Awardable' do
    let(:issue) { create(:issue) }

    it 'sorts in ascending fashion' do
      create_list(:award_emoji, 3, awardable: issue)

      expect(issue.award_emoji).to eq issue.award_emoji.sort_by(&:id)
    end
  end
end
