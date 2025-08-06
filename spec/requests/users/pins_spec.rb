# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pinning navigation menu items', feature_category: :navigation do
  let(:user) { create(:user) }
  let(:panel) { 'project' }
  let(:menu_item_ids) { %w[item4 item7] }
  let(:old_menu_item_ids) { %w[item4] }
  let(:other_panel_data) { { 'group' => ['some_item_id'] } }

  before do
    user.update!(pinned_nav_items: { **other_panel_data, panel => old_menu_item_ids })
    sign_in(user)
  end

  describe 'PUT /-/users/pins' do
    let(:params) { { menu_item_ids: menu_item_ids, panel: panel } }

    subject(:update_pins) { put pins_path, params: params, headers: { 'ACCEPT' => 'application/json' } }

    context 'with valid params' do
      before do
        update_pins
      end

      it 'saves the menu_item_ids for the correct panel' do
        expect(user.pinned_nav_items).to include(panel => menu_item_ids)
      end

      it 'does not change menu_item_ids of other panels' do
        expect(user.pinned_nav_items).to include(other_panel_data)
      end

      it 'responds OK' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with tracking' do
      it 'tracks pin nav item event' do
        expect { update_pins }
          .to trigger_internal_events('pin_nav_item_on_sidebar').with(
            user: user,
            category: 'Users::PinsController',
            additional_properties: {
              label: panel,
              property: 'item7'
            }
          )
      end

      it 'tracks unpin nav item event' do
        expect do
          put pins_path, params: { panel: panel, menu_item_ids: [] }, headers: { 'ACCEPT' => 'application/json' }
        end
          .to trigger_internal_events('unpin_nav_item_from_sidebar').with(
            user: user,
            category: 'Users::PinsController',
            additional_properties: {
              label: panel,
              property: 'item4'
            }
          )
      end
    end

    context 'with invalid params' do
      before do
        update_pins
      end

      shared_examples 'unchanged data and error response' do
        it 'does not modify existing panel data' do
          pinned_items = { **other_panel_data, panel => old_menu_item_ids }
          expect(user.reload.pinned_nav_items).to eq(pinned_items)
        end

        it 'responds with error' do
          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'does not track an event' do
          expect(update_pins).not_to trigger_internal_events
        end
      end

      context 'when panel name is unknown' do
        let(:params) { { menu_item_ids: menu_item_ids, panel: 'something_else' } }

        it_behaves_like 'unchanged data and error response'
      end

      context 'when menu_item_ids is not array of strings' do
        let(:params) { { menu_item_ids: 'not_an_array', panel: 'project' } }

        it_behaves_like 'unchanged data and error response'
      end

      context 'when params are not permitted' do
        let(:params) { { random_param: 'random_value' } }

        it_behaves_like 'unchanged data and error response'
      end
    end

    context 'when request size exceeds 100 kilobyte' do
      let(:too_large_string) { 'a' * 200.kilobytes }
      let(:params) { { menu_item_ids: [too_large_string], panel: 'project' } }

      it 'responds with :payload_too_large' do
        update_pins
        expect(response).to have_gitlab_http_status(:payload_too_large)
      end
    end
  end
end
