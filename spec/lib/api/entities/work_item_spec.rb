# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItem, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  subject(:entity) do
    described_class.new(work_item, current_user: user).as_json
  end

  describe 'type field' do
    context 'when work_item has a type with base_type' do
      it 'returns the uppercased base_type' do
        expect(entity[:type]).to eq(work_item.work_item_type.base_type.upcase)
      end
    end

    context 'when work_item_type is nil' do
      before do
        allow(work_item).to receive(:work_item_type).and_return(nil)
      end

      it 'returns nil' do
        expect(entity[:type]).to be_nil
      end
    end
  end
end
