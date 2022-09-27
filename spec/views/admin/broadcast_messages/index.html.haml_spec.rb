# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/broadcast_messages/index' do
  let(:role_targeted_broadcast_messages) { true }
  let(:vue_broadcast_messages) { false }

  let_it_be(:message) { create(:broadcast_message, broadcast_type: 'banner', target_access_levels: [Gitlab::Access::GUEST, Gitlab::Access::DEVELOPER]) }

  before do
    assign(:broadcast_messages, BroadcastMessage.page(1))
    assign(:broadcast_message, BroadcastMessage.new)

    stub_feature_flags(role_targeted_broadcast_messages: role_targeted_broadcast_messages)
    stub_feature_flags(vue_broadcast_messages: vue_broadcast_messages)

    render
  end

  describe 'Target roles select and table column' do
    it 'rendered' do
      expect(rendered).to have_content('Target roles')
      expect(rendered).to have_content('Owner')
      expect(rendered).to have_content('Guest, Developer')
    end

    context 'when feature flag is off' do
      let(:role_targeted_broadcast_messages) { false }

      it 'is not rendered' do
        expect(rendered).not_to have_content('Target roles')
        expect(rendered).not_to have_content('Owner')
        expect(rendered).not_to have_content('Guest, Developer')
      end
    end
  end

  describe 'Vue application' do
    it 'is not rendered' do
      expect(rendered).not_to have_selector('#js-broadcast-messages')
    end

    context 'when feature flag is on' do
      let(:vue_broadcast_messages) { true }

      it 'is rendered' do
        expect(rendered).to have_selector('#js-broadcast-messages')
      end
    end
  end
end
