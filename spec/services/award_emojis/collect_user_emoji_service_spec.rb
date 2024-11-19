# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::CollectUserEmojiService, feature_category: :team_planning do
  describe '#execute' do
    it 'returns an Array containing the awarded emoji names' do
      user = create(:user)

      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_UP)
      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_UP)
      create(:award_emoji, user: user, name: AwardEmoji::THUMBS_DOWN)

      awarded = described_class.new(user).execute

      expect(awarded).to eq([{ name: AwardEmoji::THUMBS_UP }, { name: AwardEmoji::THUMBS_DOWN }])
    end

    it 'returns an empty Array when no user is given' do
      awarded = described_class.new.execute

      expect(awarded).to be_empty
    end
  end
end
