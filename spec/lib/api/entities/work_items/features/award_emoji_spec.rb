# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::AwardEmoji, feature_category: :portfolio_management do
  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::AwardEmojiType,
    exceptions: %w[widget_definition award_emoji]

  describe '#as_json' do
    let(:user) { build_stubbed(:user) }
    let(:work_item) { build_stubbed(:work_item) }
    let(:award_emoji_counts) { { work_item.id => { up: 2, down: 1 } } }

    let(:widget) do
      instance_double(
        WorkItems::Widgets::AwardEmoji,
        work_item: work_item,
        new_custom_emoji_path: '/groups/foo/-/custom_emoji/new'
      )
    end

    subject(:representation) do
      described_class.new(widget, current_user: user, award_emoji_counts: award_emoji_counts).as_json
    end

    it 'exposes the upvote count from the pre-computed counts' do
      expect(representation[:upvotes]).to eq(2)
    end

    it 'exposes the downvote count from the pre-computed counts' do
      expect(representation[:downvotes]).to eq(1)
    end

    it 'exposes the new_custom_emoji_path from the widget for the current user' do
      expect(widget).to receive(:new_custom_emoji_path).with(user).and_return('/groups/foo/-/custom_emoji/new')

      expect(representation[:new_custom_emoji_path]).to eq('/groups/foo/-/custom_emoji/new')
    end

    context 'when new_custom_emoji_path is nil' do
      let(:widget) do
        instance_double(
          WorkItems::Widgets::AwardEmoji,
          work_item: work_item,
          new_custom_emoji_path: nil
        )
      end

      it 'exposes nil new_custom_emoji_path' do
        expect(representation[:new_custom_emoji_path]).to be_nil
      end
    end

    context 'when there are no pre-computed counts for the work item' do
      let(:award_emoji_counts) { {} }

      it 'returns zero counts' do
        expect(representation[:upvotes]).to eq(0)
        expect(representation[:downvotes]).to eq(0)
      end
    end

    context 'when award_emoji_counts option is not provided' do
      subject(:representation) { described_class.new(widget, current_user: user).as_json }

      it 'returns zero counts' do
        expect(representation[:upvotes]).to eq(0)
        expect(representation[:downvotes]).to eq(0)
      end
    end
  end
end
