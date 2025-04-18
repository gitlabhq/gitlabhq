# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::AwardEmoji, feature_category: :team_planning do
  let_it_be(:user_developer) { create(:user) }
  let_it_be(:user_guest) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_within_group) { create(:project, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project_within_group) }
  let_it_be(:work_item_without_group) { create(:work_item, project: project) }
  let_it_be(:emoji1) { create(:award_emoji, name: 'star', awardable: work_item) }
  let_it_be(:emoji2) { create(:award_emoji, :upvote, awardable: work_item) }
  let_it_be(:emoji3) { create(:award_emoji, :downvote, awardable: work_item) }
  let(:expected_path) { "/groups/#{group.full_path}/-/custom_emoji/new" }

  before_all do
    group.add_developer(user_developer)
    project.add_developer(user_developer)
  end

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

  describe '#new_custom_emoji_path' do
    it 'returns the new custom emoji path when user has permissions' do
      expect(described_class.new(work_item).new_custom_emoji_path(user_developer)).to eq(expected_path)
    end

    it 'returns nil when user does not have permissions' do
      expect(described_class.new(work_item).new_custom_emoji_path(user_guest)).to be_nil
    end

    it 'returns nil when work item is not within a group' do
      expect(described_class.new(work_item_without_group).new_custom_emoji_path(user_developer)).to be_nil
    end
  end
end
