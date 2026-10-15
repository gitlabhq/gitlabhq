# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HooksController, feature_category: :webhooks do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'organization scoping', :enable_admin_mode, :with_current_organization do
    let(:organization) { current_organization }

    describe 'GET /admin/hooks' do
      it_behaves_like 'system hook listing scoped to the organization' do
        def listed_system_hook_ids
          get admin_hooks_path

          response.body.scan(%r{/admin/hooks/(\d+)/edit}).flatten.map(&:to_i)
        end
      end
    end

    describe 'GET /admin/hooks/:id/edit' do
      it_behaves_like 'system hook lookup scoped to the organization' do
        def request_system_hook(hook)
          get edit_admin_hook_path(hook)
        end
      end
    end

    describe 'PUT /admin/hooks/:id' do
      it_behaves_like 'system hook lookup scoped to the organization' do
        def request_system_hook(hook)
          put admin_hook_path(hook), params: { hook: { url: 'http://example.com/changed' } }
        end
      end
    end

    describe 'DELETE /admin/hooks/:id' do
      it_behaves_like 'system hook lookup scoped to the organization' do
        def request_system_hook(hook)
          delete admin_hook_path(hook)
        end
      end
    end

    describe 'POST /admin/hooks/:id/test' do
      it_behaves_like 'system hook lookup scoped to the organization' do
        def request_system_hook(hook)
          post test_admin_hook_path(hook), params: { trigger: 'push_events' }
        end
      end
    end
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
