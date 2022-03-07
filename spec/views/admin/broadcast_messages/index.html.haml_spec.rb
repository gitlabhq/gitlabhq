# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/broadcast_messages/index' do
  describe 'Target roles select and table column' do
    let(:feature_flag_state) { true }

    let_it_be(:message) { create(:broadcast_message, broadcast_type: 'banner', target_access_levels: [Gitlab::Access::GUEST, Gitlab::Access::DEVELOPER]) }

    before do
      assign(:broadcast_messages, BroadcastMessage.page(1))
      assign(:broadcast_message, BroadcastMessage.new)

      stub_feature_flags(role_targeted_broadcast_messages: feature_flag_state)

      render
    end

    it 'rendered' do
      expect(rendered).to have_content('Target roles')
      expect(rendered).to have_content('Owner')
      expect(rendered).to have_content('Guest, Developer')
    end

    context 'when feature flag is off' do
      let(:feature_flag_state) { false }

      it 'is not rendered' do
        expect(rendered).not_to have_content('Target roles')
        expect(rendered).not_to have_content('Owner')
        expect(rendered).not_to have_content('Guest, Developer')
      end
    end
  end
end
