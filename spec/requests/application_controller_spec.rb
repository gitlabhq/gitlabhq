# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationController, type: :request, feature_category: :shared do
  let_it_be_with_reload(:user) { create(:user) }

  it_behaves_like 'Base action controller' do
    before do
      sign_in(user)
    end

    subject(:request) { get root_path }
  end

  it 'does not send Link header', :use_clean_rails_redis_caching do
    sign_in(user)

    get root_path

    expect(response.headers['Link']).to be_nil
  end

  describe 'session expiration' do
    context 'when user is authenticated' do
      it 'does not set the expire_after option' do
        sign_in(user)

        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to be_nil
      end
    end

    context 'when user is unauthenticated' do
      it 'sets the expire_after option' do
        get root_path

        expect(request.env['rack.session.options'][:expire_after]).to eq(
          Settings.gitlab['unauthenticated_session_expire_delay']
        )
      end
    end
  end

  describe 'unknown route' do
    # This spec targets CI environment with precompiled assets to trigger
    # Sprockets' `File.binread` and find encoding issues.
    #
    # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17627#note_1782396646
    it 'returns 404 even when locale contains UTF-8 chars' do
      user.update!(preferred_language: 'ZH-cn')

      sign_in(user)

      get "/some/undefined/path"

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.body.encoding.name).to eq('UTF-8')
    end
  end

  describe 'User-Agent header' do
    before do
      sign_in(user)

      get root_path, headers: { 'User-Agent': user_agent }
    end

    context 'when missing' do
      let(:user_agent) { nil }

      it { expect(response).to have_gitlab_http_status(:ok) }
    end

    context 'when correct' do
      let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }

      it { expect(response).to have_gitlab_http_status(:ok) }
    end

    context 'when too long' do
      let(:user_agent) { 'a' * 3000 }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  describe 'HTTP Router headers' do
    before do
      sign_in(user)
    end

    it 'includes the HTTP ROUTER headers in ApplicationContext' do
      expect_next_instance_of(RootController) do |controller|
        expect(controller).to receive(:index).and_wrap_original do |m, *args|
          m.call(*args)

          expect(Gitlab::ApplicationContext.current).to include(
            'meta.http_router_rule_action' => 'classify',
            'meta.http_router_rule_type' => 'FirstCell'
          )
        end
      end

      get root_path, headers: {
        'X-Gitlab-Http-Router-Rule-Action' => 'classify',
        'X-Gitlab-Http-Router-Rule-Type' => 'FirstCell'
      }
    end
  end
end
