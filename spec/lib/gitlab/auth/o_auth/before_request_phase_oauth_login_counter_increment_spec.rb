# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::BeforeRequestPhaseOauthLoginCounterIncrement, feature_category: :system_access do
  describe '.call' do
    let(:env) { { 'omniauth.strategy' => omniauth_strategy } }
    let(:omniauth_strategy) { instance_double(OmniAuth::Strategies::GoogleOauth2, name: 'google_oauth2') }

    it 'increments Prometheus counter for the given provider',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/524007' do
      expect { described_class.call(env) }
        .to change { gitlab_metric_omniauth_login_total_for('google_oauth2', 'initiated') }.by(1)
    end

    context 'when omniauth strategy is nil' do
      let(:omniauth_strategy) { nil }

      it 'does not increment counter' do
        expect { described_class.call(env) }
          .to change { gitlab_metric_omniauth_login_total_for('google_oauth2', 'initiated') }.by(0)

        expect(gitlab_metric_omniauth_login_total_for(nil, 'initiated')).to eq 0
      end
    end

    def gitlab_metric_omniauth_login_total_for(omniauth_provider, status)
      Gitlab::Metrics.registry.get(:gitlab_omniauth_login_total)
                              &.get(omniauth_provider: omniauth_provider, status: status)
                              .to_f
    end
  end
end
