# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth Rack middlewares', feature_category: :system_access do
  describe 'OmniAuth before_request_phase callback' do
    it 'increments Prometheus counter' do
      post('/users/auth/google_oauth2')

      counter = Gitlab::Metrics.registry.get(:gitlab_omniauth_login_total)
      expect(counter.get(omniauth_provider: 'google_oauth2', status: 'initiated')).to eq(1)
    end
  end
end
