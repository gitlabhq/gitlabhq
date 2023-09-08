# frozen_string_literal: true

require 'spec_helper'

# The AnonymousController doesn't support setting the CSP
# This is why an arbitrary test request was chosen instead
# of testing in application_controller_spec.
RSpec.describe 'Content Security Policy', feature_category: :application_instrumentation do
  let(:snowplow_host) { 'snowplow.example.com' }
  let(:vite_origin) { "#{ViteRuby.instance.config.host}:#{ViteRuby.instance.config.port}" }

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

    context 'when vite enabled during development',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424334' do
      before do
        stub_rails_env('development')
        stub_feature_flags(vite: true)

        get explore_root_url
      end

      it 'adds vite csp' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Security-Policy']).to include(vite_origin)
      end
    end

    context 'when vite disabled' do
      before do
        stub_feature_flags(vite: false)

        get explore_root_url
      end

      it "doesn't add vite csp" do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Security-Policy']).not_to include(vite_origin)
      end
    end
  end
end
