# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::UserAuthFinders do
  include described_class

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end
  let(:request) { ActionDispatch::Request.new(env) }

  def set_param(key, value)
    request.update_param(key, value)
  end

  describe '#find_user_from_warden' do
    context 'with CSRF token' do
      before do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'with invalid credentials' do
        it 'returns nil' do
          expect(find_user_from_warden).to be_nil
        end
      end

      context 'with valid credentials' do
        it 'returns the user' do
          env['warden'] = double("warden", authenticate: user)

          expect(find_user_from_warden).to eq user
        end
      end
    end

    context 'without CSRF token' do
      it 'returns nil' do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)
        env['warden'] = double("warden", authenticate: user)

        expect(find_user_from_warden).to be_nil
      end
    end
  end

  describe '#find_user_from_feed_token' do
    context 'when the request format is atom' do
      before do
        env['SCRIPT_NAME'] = 'url.atom'
        env['HTTP_ACCEPT'] = 'application/atom+xml'
      end

      context 'when feed_token param is provided' do
        it 'returns user if valid feed_token' do
          set_param(:feed_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if feed_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid feed_token' do
          set_param(:feed_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when rss_token param is provided' do
        it 'returns user if valid rssd_token' do
          set_param(:rss_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if rss_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid rss_token' do
          set_param(:rss_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end

    context 'when the request format is not atom' do
      it 'returns nil' do
        env['SCRIPT_NAME'] = 'json'

        set_param(:feed_token, user.feed_token)

        expect(find_user_from_feed_token(:rss)).to be_nil
      end
    end

    context 'when the request format is empty' do
      it 'the method call does not modify the original value' do
        env['SCRIPT_NAME'] = 'url.atom'

        env.delete('action_dispatch.request.formats')

        find_user_from_feed_token(:rss)

        expect(env['action_dispatch.request.formats']).to be_nil
      end
    end
  end

  describe '#find_user_from_static_object_token' do
    shared_examples 'static object request' do
      before do
        env['SCRIPT_NAME'] = path
      end

      context 'when token header param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            request.headers['X-Gitlab-Static-Object-Token'] = user.static_object_token

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'returns the user' do
            request.headers['X-Gitlab-Static-Object-Token'] = 'foobar'

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end

      context 'when token query param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            set_param(:token, user.static_object_token)

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'returns the user' do
            set_param(:token, 'foobar')

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end
    end

    context 'when request format is archive' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/-/archive/master.zip' }
        let_it_be(:format) { :archive }
      end
    end

    context 'when request format is blob' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/raw/master/README.md' }
        let_it_be(:format) { :blob }
      end
    end

    context 'when request format is not archive nor blob' do
      before do
        env['script_name'] = 'url'
      end

      it 'returns nil' do
        expect(find_user_from_static_object_token(:foo)).to be_nil
      end
    end
  end

  describe '#find_user_from_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      env['SCRIPT_NAME'] = 'url.atom'
    end

    it 'returns nil if no access_token present' do
      expect(find_user_from_access_token).to be_nil
    end

    context 'when validate_access_token! returns valid' do
      it 'returns user' do
        env[Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect(find_user_from_access_token).to eq user
      end

      it 'returns exception if token has no user' do
        env[Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
        allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

        expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'with OAuth headers' do
      it 'returns user' do
        env['HTTP_AUTHORIZATION'] = "Bearer #{personal_access_token.token}"

        expect(find_user_from_access_token).to eq user
      end

      it 'returns exception if invalid personal_access_token' do
        env['HTTP_AUTHORIZATION'] = 'Bearer invalid_20byte_token'

        expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end
  end

  describe '#find_user_from_web_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      env[Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token
    end

    it 'returns exception if token has no user' do
      allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

      expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end

    context 'no feed or API requests' do
      it 'returns nil if the request is not RSS' do
        expect(find_user_from_web_access_token(:rss)).to be_nil
      end

      it 'returns nil if the request is not ICS' do
        expect(find_user_from_web_access_token(:ics)).to be_nil
      end

      it 'returns nil if the request is not API' do
        expect(find_user_from_web_access_token(:api)).to be_nil
      end
    end

    it 'returns the user for RSS requests' do
      env['SCRIPT_NAME'] = 'url.atom'

      expect(find_user_from_web_access_token(:rss)).to eq(user)
    end

    it 'returns the user for ICS requests' do
      env['SCRIPT_NAME'] = 'url.ics'

      expect(find_user_from_web_access_token(:ics)).to eq(user)
    end

    it 'returns the user for API requests' do
      env['SCRIPT_NAME'] = '/api/endpoint'

      expect(find_user_from_web_access_token(:api)).to eq(user)
    end
  end

  describe '#find_personal_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      env['SCRIPT_NAME'] = 'url.atom'
    end

    context 'passed as header' do
      it 'returns token if valid personal_access_token' do
        env[Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_HEADER] = personal_access_token.token

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    context 'passed as param' do
      it 'returns token if valid personal_access_token' do
        set_param(Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_PARAM, personal_access_token.token)

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    it 'returns nil if no personal_access_token' do
      expect(find_personal_access_token).to be_nil
    end

    it 'returns exception if invalid personal_access_token' do
      env[Gitlab::Auth::UserAuthFinders::PRIVATE_TOKEN_HEADER] = 'invalid_token'

      expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#find_oauth_access_token' do
    let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
    let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api') }

    context 'passed as header' do
      it 'returns token if valid oauth_access_token' do
        env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"

        expect(find_oauth_access_token.token).to eq token.token
      end
    end

    context 'passed as param' do
      it 'returns user if valid oauth_access_token' do
        set_param(:access_token, token.token)

        expect(find_oauth_access_token.token).to eq token.token
      end
    end

    it 'returns nil if no oauth_access_token' do
      expect(find_oauth_access_token).to be_nil
    end

    it 'returns exception if invalid oauth_access_token' do
      env['HTTP_AUTHORIZATION'] = "Bearer invalid_token"

      expect { find_oauth_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#validate_access_token!' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    it 'returns nil if no access_token present' do
      expect(validate_access_token!).to be_nil
    end

    context 'token is not valid' do
      before do
        allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      end

      it 'returns Gitlab::Auth::ExpiredError if token expired' do
        personal_access_token.expires_at = 1.day.ago

        expect { validate_access_token! }.to raise_error(Gitlab::Auth::ExpiredError)
      end

      it 'returns Gitlab::Auth::RevokedError if token revoked' do
        personal_access_token.revoke!

        expect { validate_access_token! }.to raise_error(Gitlab::Auth::RevokedError)
      end

      it 'returns Gitlab::Auth::InsufficientScopeError if invalid token scope' do
        expect { validate_access_token!(scopes: [:sudo]) }.to raise_error(Gitlab::Auth::InsufficientScopeError)
      end
    end

    context 'with impersonation token' do
      let(:personal_access_token) { create(:personal_access_token, :impersonation, user: user) }

      context 'when impersonation is disabled' do
        before do
          stub_config_setting(impersonation_enabled: false)
          allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
        end

        it 'returns Gitlab::Auth::ImpersonationDisabled' do
          expect { validate_access_token! }.to raise_error(Gitlab::Auth::ImpersonationDisabled)
        end
      end
    end
  end
end
