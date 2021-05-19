# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomEmoji do
  describe 'Associations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:custom_emoji) }
    it { is_expected.to belong_to(:creator).inverse_of(:created_custom_emoji) }
    it { is_expected.to have_db_column(:file) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_length_of(:name).is_at_most(36) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_db_column(:external) }
  end

  describe 'exclusion of duplicated emoji' do
    let(:emoji_name) { Gitlab::Emoji.emojis_names.sample }
    let(:group) { create(:group, :private) }

    it 'disallows emoji names of built-in emoji' do
      new_emoji = build(:custom_emoji, name: emoji_name, group: group)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(name: ["#{emoji_name} is already being used for another emoji"])
    end

    it 'disallows very long invalid emoji name without regular expression backtracking issues' do
      new_emoji = build(:custom_emoji, name: 'a' * 10000 + '!', group: group)

      Timeout.timeout(1) do
        expect(new_emoji).not_to be_valid
        expect(new_emoji.errors.messages).to eq(name: ["is too long (maximum is 36 characters)", "is invalid"])
      end
    end

    it 'disallows duplicate custom emoji names within namespace' do
      old_emoji = create(:custom_emoji, group: group)
      new_emoji = build(:custom_emoji, name: old_emoji.name, namespace: old_emoji.namespace, group: group)

      expect(new_emoji).not_to be_valid
      expect(new_emoji.errors.messages).to eq(creator: ["can't be blank"], name: ["has already been taken"])
    end

    it 'disallows non http and https file value' do
      emoji = build(:custom_emoji, name: 'new-name', group: group, file: 'ftp://some-url.in')

      expect(emoji).not_to be_valid
      expect(emoji.errors.messages).to eq(file: ["is blocked: Only allowed schemes are http, https"])
    end
  end
end
