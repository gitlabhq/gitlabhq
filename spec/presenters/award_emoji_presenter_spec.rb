# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojiPresenter do
  let(:emoji_name) { AwardEmoji::THUMBS_UP }
  let(:award_emoji) { build(:award_emoji, name: emoji_name) }
  let(:presenter) { described_class.new(award_emoji) }
  let(:emoji) { TanukiEmoji.find_by_alpha_code(emoji_name) }

  describe '#description' do
    it { expect(presenter.description).to eq emoji.description }
  end

  describe '#unicode' do
    it { expect(presenter.unicode).to eq emoji.hex }
  end

  describe '#unicode_version' do
    it { expect(presenter.unicode_version).to eq('6.0') }
  end

  describe '#emoji' do
    it { expect(presenter.emoji).to eq emoji.codepoints }
  end

  describe 'when presenting an award emoji with an invalid name' do
    let(:emoji_name) { 'invalid-name' }

    it 'returns nil for all properties' do
      expect(presenter.description).to be_nil
      expect(presenter.emoji).to be_nil
      expect(presenter.unicode).to be_nil
      expect(presenter.unicode_version).to be_nil
    end
  end
end
