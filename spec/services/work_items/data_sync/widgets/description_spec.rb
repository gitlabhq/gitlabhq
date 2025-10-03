# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Description, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:last_edited_at) { DateTime.now }
  let_it_be(:work_item) do
    create(:work_item, description: "Move weight widget data", last_edited_at: last_edited_at,
      last_edited_by: current_user)
  end

  let_it_be(:target_work_item) { create(:work_item) }

  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#before_create' do
    context 'when target work item does not have description widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:description).and_return(false)
      end

      it 'does not copy any description data' do
        expect { callback.before_create }.to not_change { target_work_item.description }
          .and not_change { target_work_item.description_html }
          .and not_change { target_work_item.last_edited_at }
          .and not_change { target_work_item.last_edited_by }
      end
    end

    it 'copies all the description data' do
      expect { callback.before_create }.to change { target_work_item.description }.from(nil).to(work_item.description)
        .and change { target_work_item.description_html }.from("").to(work_item.description_html)
        .and change { target_work_item.last_edited_at }.from(nil).to(last_edited_at)
        .and change { target_work_item.last_edited_by }.from(nil).to(current_user)
    end

    it 'sets work_item_description record' do
      callback.before_create

      target_work_item.save!

      expect(target_work_item.work_item_description).to be_persisted
      expect(target_work_item.reload.work_item_description).to have_attributes(
        description: target_work_item.description,
        description_html: target_work_item.description_html,
        last_edited_at: target_work_item.last_edited_at,
        last_editing_user: target_work_item.last_edited_by
      )
    end
  end
end
