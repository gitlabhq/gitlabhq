# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/services/_form' do
  let(:project) { create(:redmine_project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)

    allow(view).to receive_messages(
      current_user: user,
      can?: true,
      current_application_settings: Gitlab::CurrentSettings.current_application_settings,
      integration: project.redmine_integration,
      request: double(referer: '/services')
    )
  end

  context 'integrations form' do
    it 'does not render form element' do
      render

      expect(rendered).not_to have_selector('[data-testid="integration-form"]')
    end

    context 'when vue_integration_form feature flag is disabled' do
      before do
        stub_feature_flags(vue_integration_form: false)
      end

      it 'renders form element' do
        render

        expect(rendered).to have_selector('[data-testid="integration-form"]')
      end

      context 'commit_events and merge_request_events' do
        it 'display merge_request_events and commit_events descriptions' do
          allow(Integrations::Redmine).to receive(:supported_events).and_return(%w(commit merge_request))

          render

          expect(rendered).to have_css("input[name='redirect_to'][value='/services']", count: 1, visible: false)
        end
      end
    end
  end
end
