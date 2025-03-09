# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth Rack middlewares', feature_category: :system_access do
  describe 'OmniAuth before_request_phase callback' do
    it 'increments Prometheus counter' do
      expect { post('/users/auth/google_oauth2') }
        .to change {
          Gitlab::Metrics.registry.get(:gitlab_omniauth_login_total)
                                  &.get(omniauth_provider: 'google_oauth2', status: 'initiated')
                                  .to_f
        }.by(1)
    end
  end
end
