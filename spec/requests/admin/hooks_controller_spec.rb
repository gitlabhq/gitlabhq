# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HooksController, feature_category: :webhooks do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  # The column is on the shared web_hooks table, so a system hook can carry it, but a
  # system hook has no container to gate the attribute on.
  describe 'duo_flow_callback_enabled', :enable_admin_mode do
    subject(:create_hook) do
      post admin_hooks_path, params: {
        hook: { url: 'http://example.com', duo_flow_callback_enabled: true }
      }
    end

    it 'does not set the attribute on create' do
      create_hook

      expect(SystemHook.last.duo_flow_callback_enabled).to be(false)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: false)
      end

      it 'does not set the attribute on create' do
        create_hook

        expect(SystemHook.last.duo_flow_callback_enabled).to be(false)
      end
    end
  end
end
