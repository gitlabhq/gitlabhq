# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::BaseService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:awardable) { create(:note, project: project) }

  let(:emoji_name) { 'horse' }

  describe '.initialize' do
    subject { described_class }

    it 'uses same emoji name if not an alias' do
      expect(subject.new(awardable, emoji_name, current_user).name).to eq(emoji_name)
    end

    it 'uses emoji original name if its an alias' do
      emoji_alias = 'small_airplane'
      emoji_name = 'airplane_small'

      expect(subject.new(awardable, emoji_alias, current_user).name).to eq(emoji_name)
    end
  end

  describe '.execute_hooks' do
    let(:award_emoji) { create(:award_emoji, awardable: awardable) }
    let(:action) { 'award' }

    subject { described_class.new(awardable, emoji_name, current_user) }

    context 'with no emoji hooks configured' do
      it 'does not build hook_data' do
        expect(Gitlab::DataBuilder::Emoji).not_to receive(:build)
        expect(award_emoji.awardable.project).not_to receive(:execute_hooks)

        subject.execute_hooks(award_emoji, action)
      end
    end

    context 'with emoji hooks configured' do
      it 'builds hook_data and calls execute_hooks for project' do
        hook_data = {}
        create(:project_hook, project: project, emoji_events: true)
        expect(Gitlab::DataBuilder::Emoji).to receive(:build).and_return(hook_data)
        expect(award_emoji.awardable.project).to receive(:execute_hooks).with(hook_data, :emoji_hooks)

        subject.execute_hooks(award_emoji, action)
      end
    end
  end
end
