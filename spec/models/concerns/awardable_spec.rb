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
      before do
        award_emoji.update_column(:name, 'thumbsdown')
        award_emoji2.update_column(:name, 'thumbsup')
      end

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

  describe '#user_can_award?' do
    let(:user) { create(:user) }

    before do
      issue.project.add_guest(user)
    end

    it 'does not allow upvoting or downvoting your own issue' do
      issue.update!(author: user)

      expect(issue.user_can_award?(user, AwardEmoji::DOWNVOTE_NAMES.sample)).to be_falsy
      expect(issue.user_can_award?(user, AwardEmoji::UPVOTE_NAMES.sample)).to be_falsy
    end

    it 'is truthy when the user is allowed to award emoji' do
      expect(issue.user_can_award?(user, AwardEmoji::UPVOTE_NAMES.sample)).to be_truthy
    end

    it 'is falsy when the project is archived' do
      issue.project.update!(archived: true)

      expect(issue.user_can_award?(user, AwardEmoji::UPVOTE_NAMES.sample)).to be_falsy
    end
  end

  describe "#toggle_award_emoji" do
    before do
      award_emoji.update_column(:name, 'thumbsdown')
    end

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
