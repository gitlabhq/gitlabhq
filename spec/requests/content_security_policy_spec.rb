# frozen_string_literal: true

require 'spec_helper'

# The AnonymousController doesn't support setting the CSP
# This is why an arbitrary test request was chosen instead
# of testing in application_controller_spec.
RSpec.describe 'Content Security Policy', feature_category: :application_instrumentation do
  let(:snowplow_host) { 'snowplow.example.com' }

  shared_examples 'snowplow is not in the CSP' do
    it 'does not add the snowplow collector hostname to the CSP' do
      get explore_root_url

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Security-Policy']).not_to include(snowplow_host)
    end
  end

  describe 'GET #explore' do
    context 'snowplow is enabled' do
      before do
        stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: snowplow_host)
      end

      it 'adds the snowplow collector hostname to the CSP' do
        get explore_root_url

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Security-Policy']).to include(snowplow_host)
      end
    end

    context 'snowplow is enabled but host is not configured' do
      before do
        stub_application_setting(snowplow_enabled: true)
      end

      it_behaves_like 'snowplow is not in the CSP'
    end

    context 'snowplow is disabled' do
      before do
        stub_application_setting(snowplow_enabled: false, snowplow_collector_hostname: snowplow_host)
      end

      it_behaves_like 'snowplow is not in the CSP'
    end
  end
end
