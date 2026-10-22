# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session expiry header', :clean_gitlab_redis_sessions, feature_category: :system_access do
  include ApiHelpers
  include LoginHelpers

  let_it_be(:user) { create(:user) }

  # A method rather than a `let`, so examples that make more than one request read the
  # header of the latest response instead of a memoized one.
  def header
    response.headers[Gitlab::Middleware::SessionExpiryHeader::HEADER]
  end

  before do
    stub_basic_saml_config
  end

  context 'with a signed in user' do
    before do
      login_as(user)
    end

    it 'is returned on a page' do
      get root_path

      expect(header).to be_present
    end

    it 'is returned on a GraphQL request' do
      post '/api/graphql', params: { query: '{ currentUser { id } }' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(header).to be_present
    end

    # The API is mounted alongside Rails and does not share its controllers, so a controller
    # hook would miss it - a REST-driven page would believe its session had expired while alive.
    it 'is returned on a session authenticated API request' do
      get api('/projects')

      expect(response).to have_gitlab_http_status(:ok)
      expect(header).to be_present
    end

    # Group SAML alone (the gitlab.com case) must not open the gate.
    context 'when only group SAML is configured' do
      before do
        stub_omniauth_config(providers: [{ name: 'group_saml' }])
      end

      it 'is not returned' do
        get root_path

        expect(header).to be_nil
      end
    end

    context 'when session_expire_modal_on_saml_instances is disabled' do
      before do
        stub_feature_flags(session_expire_modal_on_saml_instances: false)
      end

      it 'is not returned' do
        get root_path

        expect(header).to be_nil
      end
    end
  end

  context 'when sessions expire from the time of sign-in' do
    before do
      stub_application_setting(session_expire_from_init: true)
      stub_feature_flags(session_expire_modal_on_saml_instances: false)
      stub_omniauth_config(providers: [{ name: 'group_saml' }])
      login_as(user)
    end

    it 'is returned regardless of SAML and the flag' do
      get root_path

      expect(header).to be_present
    end

    context 'when the activity deadline also applies' do
      before do
        stub_basic_saml_config
        stub_feature_flags(session_expire_modal_on_saml_instances: true)
      end

      it 'reports the sign-in deadline, unchanged by later activity', :aggregate_failures do
        freeze_time { get root_path }
        first = header

        # Past the write-throttle window, so the activity deadline would move.
        travel 2.hours do
          get root_path

          expect(first).to be_present
          expect(header).to eq(first)
        end
      end
    end
  end

  describe 'across requests' do
    before do
      login_as(user)
    end

    it 'reports the deadline from the last committed activity' do
      freeze_time { get root_path }
      first = header

      travel 2.minutes do
        get root_path

        expect(header).to eq(first)
      end

      travel 2.hours do
        get root_path

        expect(header.to_i).to be_within(1.minute).of(first.to_i + 2.hours.to_i)
      end
    end
  end

  context 'when the request skips its session commit' do
    where(:skipping_request) do
      [[:opensearch], [:collect_events]]
    end

    with_them do
      before do
        login_as(user)
      end

      def perform_skipping_request
        case skipping_request
        when :opensearch
          get search_opensearch_path(format: :xml)
        when :collect_events
          post event_forwarding_path, params: { data: [] }.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
        end
      end

      it 'reports the stored deadline', :aggregate_failures do
        freeze_time { get root_path }
        first = header

        travel 2.hours do
          perform_skipping_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(header).to eq(first)
        end
      end
    end
  end

  context 'with an anonymous request' do
    it 'is not returned' do
      get root_path

      expect(header).to be_nil
    end
  end

  context 'with a token authenticated API request' do
    let_it_be(:token) { create(:personal_access_token, user: user) }

    it 'is not returned, since there is no session to expire' do
      get api('/projects', personal_access_token: token)

      expect(response).to have_gitlab_http_status(:ok)
      expect(header).to be_nil
    end
  end
end
