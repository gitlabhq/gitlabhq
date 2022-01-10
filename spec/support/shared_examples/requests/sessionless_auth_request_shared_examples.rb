# frozen_string_literal: true

RSpec.shared_examples 'authenticates sessionless user for the request spec' do |name, public_resource:, ignore_metrics: false, params: {}|
  before do
    stub_authentication_activity_metrics(debug: false)
  end

  let_it_be(:user) { create(:user) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }

  shared_examples 'authenticates user and returns response with ok status' do
    it 'authenticates user and returns response with ok status' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)
        .and increment(:user_session_override_counter)
        .and increment(:user_sessionless_authentication_counter)

      subject

      expect(controller.current_user).to eq(user)
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'does not authenticate user and returns response with ok status' do
    it 'does not authenticate user and returns response with ok status' do
      subject

      expect(controller.current_user).to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'does not return response with ok status' do
    it 'does not return response with ok status' do
      # Several instances of where these specs are shared route the request
      #   through ApplicationController#route_not_found which does not involve
      #   the usual auth code from Devise, so does not increment the
      #   :user_unauthenticated_counter
      unless ignore_metrics
        expect(authentication_metrics)
          .to increment(:user_unauthenticated_counter)
      end

      subject

      expect(response).not_to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'using valid token' do
    context 'when resource is private', unless: public_resource do
      include_examples 'authenticates user and returns response with ok status'

      context 'when user with expired password' do
        let_it_be(:user) { create(:user, password_expires_at: 2.minutes.ago) }

        include_examples 'does not return response with ok status'
      end

      context 'when password expiration is not applicable' do
        context 'when ldap user' do
          let_it_be(:user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

          include_examples 'authenticates user and returns response with ok status'
        end
      end
    end

    context 'when resource is public', if: public_resource do
      include_examples 'authenticates user and returns response with ok status'

      context 'when user with expired password' do
        let_it_be(:user) { create(:user, password_expires_at: 2.minutes.ago) }

        include_examples 'does not authenticate user and returns response with ok status'
      end
    end
  end

  shared_examples 'using invalid token' do
    context 'when resource is private', unless: public_resource do
      include_examples 'does not return response with ok status'
    end

    context 'when resource is public', if: public_resource do
      include_examples 'does not authenticate user and returns response with ok status'
    end
  end

  shared_examples 'personal access token has no api scope' do
    context 'when the personal access token has no api scope' do
      before do
        personal_access_token.update!(scopes: [:read_user])
      end

      context 'when resource is private', unless: public_resource do
        include_examples 'does not return response with ok status'
      end

      context 'when resource is public', if: public_resource do
        include_examples 'does not authenticate user and returns response with ok status'
      end
    end
  end

  describe name do
    context "when the 'private_token' param is populated with the personal access token" do
      context 'when valid token' do
        subject { get url, params: params.merge(private_token: personal_access_token.token) }

        include_examples 'using valid token'

        include_examples 'personal access token has no api scope'
      end

      context 'when invalid token' do
        subject { get url, params: params.merge(private_token: 'invalid token') }

        include_examples 'using invalid token'
      end
    end

    context "when the 'PRIVATE-TOKEN' header is populated with the personal access token" do
      context 'when valid token' do
        subject do
          headers = { 'PRIVATE-TOKEN': personal_access_token.token }
          get url, params: params, headers: headers
        end

        include_examples 'using valid token'

        include_examples 'personal access token has no api scope'
      end

      context 'when invalid token' do
        subject do
          headers = { 'PRIVATE-TOKEN': 'invalid token' }
          get url, params: params, headers: headers
        end

        include_examples 'using invalid token'
      end
    end

    context "when the 'feed_token' param is populated with the feed token" do
      context 'when valid token' do
        subject { get url, params: params.merge(feed_token: user.feed_token) }

        include_examples 'using valid token'
      end

      context 'when invalid token' do
        subject { get url, params: params.merge(feed_token: 'invalid token') }

        include_examples 'using invalid token'
      end
    end
  end
end
