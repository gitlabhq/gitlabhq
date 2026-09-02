# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::HooksController, feature_category: :webhooks do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be_with_reload(:hook) { create(:project_hook, project: project) }

  before do
    sign_in(user)
  end

  # The attribute has to be listed in hook_param_names, otherwise the form submits it and
  # Rails discards it as unpermitted, leaving the checkbox with no effect.
  describe 'duo_flow_callback_enabled' do
    before do
      stub_feature_flags(duo_flow_callback_hooks: project.root_ancestor)
    end

    it 'persists the attribute on create' do
      post project_hooks_path(project), params: {
        hook: { url: 'http://example.com', duo_flow_callback_enabled: true }
      }

      expect(ProjectHook.order_id_desc.take.duo_flow_callback_enabled).to be(true)
    end

    it 'persists the attribute on update' do
      put project_hook_path(project, hook), params: {
        hook: { url: hook.url, duo_flow_callback_enabled: true }
      }

      expect(hook.reload.duo_flow_callback_enabled).to be(true)
    end

    # The form omits the checkbox when the feature is unavailable, so these requests stand
    # in for a hand-rolled one. The attribute is not permitted, so it never reaches the
    # record.
    context 'when the feature flag is disabled for the root namespace' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: false)
      end

      it 'does not set the attribute on create' do
        post project_hooks_path(project), params: {
          hook: { url: 'http://example.com', duo_flow_callback_enabled: true }
        }

        expect(ProjectHook.order_id_desc.take.duo_flow_callback_enabled).to be(false)
      end

      it 'does not set the attribute on update' do
        put project_hook_path(project, hook), params: {
          hook: { url: hook.url, duo_flow_callback_enabled: true }
        }

        expect(hook.reload.duo_flow_callback_enabled).to be(false)
      end
    end

    context 'when the flag is enabled for a different namespace' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: create(:group))
      end

      it 'does not set the attribute' do
        post project_hooks_path(project), params: {
          hook: { url: 'http://example.com', duo_flow_callback_enabled: true }
        }

        expect(ProjectHook.order_id_desc.take.duo_flow_callback_enabled).to be(false)
      end
    end
  end
end
