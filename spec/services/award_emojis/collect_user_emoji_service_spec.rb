# frozen_string_literal: true

require 'spec_helper'

describe AwardEmojis::CollectUserEmojiService do
  describe '#execute' do
    it 'returns an Array containing the awarded emoji names' do
      user = create(:user)

      create(:award_emoji, user: user, name: 'thumbsup')
      create(:award_emoji, user: user, name: 'thumbsup')
      create(:award_emoji, user: user, name: 'thumbsdown')

      awarded = described_class.new(user).execute

      expect(awarded).to eq([{ name: 'thumbsup' }, { name: 'thumbsdown' }])
    end

    it 'returns an empty Array when no user is given' do
      awarded = described_class.new.execute

      expect(awarded).to be_empty
    end
  end
end
