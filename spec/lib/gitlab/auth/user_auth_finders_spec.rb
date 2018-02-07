require 'spec_helper'

describe Gitlab::Auth::UserAuthFinders do
  include described_class

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end
  let(:request) { Rack::Request.new(env)}

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

  describe '#find_user_from_rss_token' do
    context 'when the request format is atom' do
      before do
        env['HTTP_ACCEPT'] = 'application/atom+xml'
      end

      it 'returns user if valid rss_token' do
        set_param(:rss_token, user.rss_token)

        expect(find_user_from_rss_token).to eq user
      end

      it 'returns nil if rss_token is blank' do
        expect(find_user_from_rss_token).to be_nil
      end

      it 'returns exception if invalid rss_token' do
        set_param(:rss_token, 'invalid_token')

        expect { find_user_from_rss_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'when the request format is not atom' do
      it 'returns nil' do
        set_param(:rss_token, user.rss_token)

        expect(find_user_from_rss_token).to be_nil
      end
    end

    context 'when the request format is empty' do
      it 'the method call does not modify the original value' do
        env['action_dispatch.request.formats'] = nil

        find_user_from_rss_token

        expect(env['action_dispatch.request.formats']).to be_nil
      end
    end
  end

  describe '#find_user_from_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    it 'returns nil if no access_token present' do
      expect(find_personal_access_token).to be_nil
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
  end

  describe '#find_personal_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

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
  end
end
