# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::AwardEmoji, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item) }
  let_it_be_with_reload(:thumbs_up) { create(:award_emoji, name: 'thumbsup', awardable: work_item) }
  let_it_be_with_reload(:thumbs_down) { create(:award_emoji, name: 'thumbsdown', awardable: work_item) }

  let_it_be(:target_work_item) { create(:work_item) }
  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#before_create' do
    context 'when target work item has award_emoji widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:award_emoji).and_return(true)
      end

      context 'when moving work item' do
        it 'copies award_emoji from work_item to target_work_item' do
          expect(callback).to receive(:new_work_item_award_emoji).and_call_original
          expect(::AwardEmoji).to receive(:insert_all).and_call_original

          expected_result = work_item.reload.award_emoji.order(user_id: :asc, name: :asc).pluck(:user_id, :name)
          callback.after_create

          emojis = target_work_item.reload.award_emoji.order(user_id: :asc, name: :asc).pluck(:user_id, :name)
          expect(emojis).to match_array(expected_result)
        end
      end

      context 'when cloning work item' do
        let(:params) { { operation: :clone } }

        it 'does not copy award_emoji' do
          expect(callback).not_to receive(:new_work_item_award_emoji)
          expect(::AwardEmoji).not_to receive(:insert_all)

          callback.after_create

          expect(target_work_item.reload.award_emoji).to be_empty
        end
      end
    end

    context 'when target work item does not have award_emoji widget' do
      before do
        target_work_item.reload
        allow(target_work_item).to receive(:get_widget).with(:award_emoji).and_return(false)
      end

      it 'does not copy award_emoji' do
        expect(callback).not_to receive(:new_work_item_award_emoji)
        expect(::AwardEmoji).not_to receive(:insert_all)

        callback.after_create

        expect(target_work_item.reload.award_emoji).to be_empty
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'is defined and can be called' do
      expect(work_item.award_emoji.count).to eq(2)
      expect { callback.post_move_cleanup }.not_to raise_error
    end

    it 'removes original work item award_emoji' do
      expect(work_item.award_emoji.count).to eq(2)

      callback.post_move_cleanup

      expect(work_item.award_emoji).to be_empty
    end

    context 'when cleanup data in batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'removes original work item award_emoji' do
        create(:award_emoji, name: 'star', awardable: work_item)
        create(:award_emoji, name: 'grinning', awardable: work_item)

        expect(work_item.award_emoji.count).to eq(4)

        callback.post_move_cleanup

        expect(work_item.reload.award_emoji).to be_empty
      end
    end
  end
end
