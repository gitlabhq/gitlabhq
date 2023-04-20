# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::AwardEmoji, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:emoji1) { create(:award_emoji, name: 'star', awardable: work_item) }
  let_it_be(:emoji2) { create(:award_emoji, :upvote, awardable: work_item) }
  let_it_be(:emoji3) { create(:award_emoji, :downvote, awardable: work_item) }

  describe '.type' do
    it { expect(described_class.type).to eq(:award_emoji) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:award_emoji) }
  end

  describe '#downvotes' do
    it { expect(described_class.new(work_item).downvotes).to eq(1) }
  end

  describe '#upvotes' do
    it { expect(described_class.new(work_item).upvotes).to eq(1) }
  end

  describe '#award_emoji' do
    it { expect(described_class.new(work_item).award_emoji).to match_array([emoji1, emoji2, emoji3]) }
  end
end
