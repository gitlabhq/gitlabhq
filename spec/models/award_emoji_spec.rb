require 'spec_helper'

describe AwardEmoji do
  describe 'Associations' do
    it { is_expected.to belong_to(:awardable) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Participable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:awardable) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:name) }

    # To circumvent a bug in the shoulda matchers
    describe "scoped uniqueness validation" do
      it "rejects duplicate award emoji" do
        user  = create(:user)
        issue = create(:issue)
        create(:award_emoji, user: user, awardable: issue)
        new_award = build(:award_emoji, user: user, awardable: issue)

        expect(new_award).not_to be_valid
      end

      # Assume User A and User B both created award emoji of the same name
      # on the same awardable. When User A is deleted, User A's award emoji
      # is moved to the ghost user. When User B is deleted, User B's award emoji
      # also needs to be moved to the ghost user - this cannot happen unless
      # the uniqueness validation is disabled for ghost users.
      it "allows duplicate award emoji for ghost users" do
        user  = create(:user, :ghost)
        issue = create(:issue)
        create(:award_emoji, user: user, awardable: issue)
        new_award = build(:award_emoji, user: user, awardable: issue)

        expect(new_award).to be_valid
      end
    end
  end
end
