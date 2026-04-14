# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/health_check/show.html.haml', :enable_admin_mode, feature_category: :error_budgets do
  let(:user) { build_stubbed(:admin) }

  before do
    assign(:errors, errors)

    allow(view).to receive(:current_user).and_return(user)
  end

  context 'when user has admin_all_resources ability' do
    context 'when there are no errors' do
      let(:errors) { '' }

      it 'renders the access token and health check URLs', :aggregate_failures do
        render

        token = Gitlab::CurrentSettings.health_check_access_token

        expect(rendered).to have_field('health_check_access_token', with: token, readonly: true)
        expect(rendered).to have_link('Reset token')
        expect(rendered).to have_content('Health information can be retrieved')
        expect(rendered).to have_content(readiness_url(token: token))
        expect(rendered).to have_content(liveness_url(token: token))
        expect(rendered).to have_content(metrics_url(token: token))
      end

      it 'renders healthy status', :aggregate_failures do
        render

        expect(rendered).to have_content('Healthy')
        expect(rendered).to have_content('No health problems detected')
      end
    end

    context 'when there are errors' do
      let(:errors) { 'Database not responding' }

      it 'renders unhealthy status with error details', :aggregate_failures do
        render

        expect(rendered).to have_content('Unhealthy')
        expect(rendered).to have_content('Database not responding')
        expect(rendered).not_to have_content('No health problems detected')
      end
    end
  end

  context 'when user does not have admin_all_resources ability' do
    let(:user) { build_stubbed(:user) }
    let(:errors) { '' }

    it 'does not render the access token or health check URLs', :aggregate_failures do
      render

      expect(rendered).not_to have_field('health_check_access_token')
      expect(rendered).not_to have_link('Reset token')
      expect(rendered).not_to have_content('Health information can be retrieved')
    end

    it 'still renders the health status section' do
      render

      expect(rendered).to have_content('Healthy')
    end
  end
end
