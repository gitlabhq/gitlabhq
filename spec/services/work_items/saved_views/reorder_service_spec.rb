# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::ReorderService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:saved_view1) { create(:saved_view, namespace: group) }
  let_it_be(:saved_view2) { create(:saved_view, namespace: group) }
  let_it_be(:saved_view3) { create(:saved_view, namespace: group) }

  let_it_be(:user_saved_view1) do
    create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group, relative_position: 1000)
  end

  let_it_be(:user_saved_view2) do
    create(:user_saved_view, user: user, saved_view: saved_view2, namespace: group, relative_position: 2000)
  end

  let_it_be(:user_saved_view3) do
    create(:user_saved_view, user: user, saved_view: saved_view3, namespace: group, relative_position: 3000)
  end

  let(:saved_view) { saved_view1 }
  let(:params) { {} }

  subject(:service_result) do
    described_class.new(current_user: user, params: params).execute(saved_view)
  end

  describe '#execute' do
    context 'when moving after another saved view' do
      let(:params) { { move_after_id: saved_view2.id } }

      it 'reorders the saved view' do
        expect { service_result }.to change { user_saved_view1.reload.relative_position }

        expect(service_result).to be_success
        expect(user_saved_view1.relative_position).to be > user_saved_view2.relative_position
      end
    end

    context 'when moving before another saved view' do
      let(:saved_view) { saved_view3 }
      let(:params) { { move_before_id: saved_view2.id } }

      it 'reorders the saved view' do
        expect { service_result }.to change { user_saved_view3.reload.relative_position }

        expect(service_result).to be_success
        expect(user_saved_view3.relative_position).to be < user_saved_view2.relative_position
      end
    end

    context 'when saved view id is same as adjacent id' do
      let(:params) { { move_after_id: saved_view1.id } }

      it 'returns an error' do
        expect(service_result).to be_error
        expect(service_result.message).to eq("Cannot reorder a saved view relative to itself")
      end
    end

    context 'when user is not subscribed to the saved view' do
      let_it_be(:other_user) { create(:user) }
      let(:params) { { move_after_id: saved_view2.id } }

      subject(:service_result) do
        described_class.new(current_user: other_user, params: params).execute(saved_view)
      end

      it 'returns an error' do
        expect(service_result).to be_error
        expect(service_result.message).to eq("Unable to find subscribed saved view(s)")
      end
    end

    context 'when adjacent saved view does not exist' do
      let(:params) { { move_after_id: non_existing_record_id } }

      it 'returns an error' do
        expect(service_result).to be_error
        expect(service_result.message).to eq("Unable to find subscribed saved view(s)")
      end
    end
  end
end
