# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomEmoji do
  describe 'Associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_db_column(:file) }
    it { is_expected.to validate_length_of(:name).is_at_most(36) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'exclusion of duplicated emoji' do
    let(:emoji_name) { Gitlab::Emoji.emojis_names.sample }

    it 'disallows emoji names of built-in emoji' do
      new_emoji = build(:custom_emoji, name: emoji_name)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(name: ["#{emoji_name} is already being used for another emoji"])
    end

    it 'disallows duplicate custom emoji names within namespace' do
      old_emoji = create(:custom_emoji)
      new_emoji = build(:custom_emoji, name: old_emoji.name, namespace: old_emoji.namespace)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(name: ["has already been taken"])
    end
  end
end
