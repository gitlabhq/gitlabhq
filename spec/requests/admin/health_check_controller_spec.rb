# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HealthCheckController, :enable_admin_mode, feature_category: :error_budgets do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET show' do
    before do
      allow(HealthCheck::Utils).to receive(:process_checks).with(['standard']).and_return(errors)
    end

    context 'when there are no errors' do
      let(:errors) { '' }

      it 'shows the healthy status', :aggregate_failures do
        get admin_health_check_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(s_('HealthCheck|No health problems detected'))
      end
    end

    context 'when there are errors' do
      let(:errors) { 'Database connection failed' }

      it 'shows the errors', :aggregate_failures do
        get admin_health_check_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Database connection failed')
      end
    end
  end
end
