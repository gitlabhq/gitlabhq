# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Identity, :request_store, feature_category: :system_access do
  describe '.link_from_oauth_token' do
    let_it_be(:actor_user) { create(:user) }
    let_it_be(:delegating_user) { create(:user) }
    let_it_be(:token_scopes) { [:api, :"user:#{delegating_user.id}"] }
    let_it_be(:oauth_access_token) { create(:oauth_access_token, user: actor_user, scopes: token_scopes) }

    subject(:identity) { described_class.link_from_oauth_token(oauth_access_token) }

    context 'when composite identity is required for the actor' do
      before do
        allow(actor_user).to receive(:has_composite_identity?).and_return(true)
      end

      it 'returns an identity' do
        expect(identity).to be_composite
        expect(identity).to be_linked
        expect(identity).to be_valid

        expect(identity.scoped_user).to eq(delegating_user)
      end

      context 'when oauth token does not have required scopes' do
        let(:oauth_access_token) { create(:oauth_access_token, user: actor_user, scopes: [:api]) }

        it 'fabricates a composite identity which is not valid' do
          expect(identity).to be_composite
          expect(identity).not_to be_linked
          expect(identity).not_to be_valid
        end
      end

      context 'when an identity link was already done for a different composite user' do
        let_it_be(:different_user) { create(:user) }
        let_it_be(:new_token_scopes) { [:api, :"user:#{different_user.id}"] }
        let_it_be(:new_oauth_access_token) { create(:oauth_access_token, user: actor_user, scopes: new_token_scopes) }

        it 'raises an error' do
          expect(identity).to be_valid

          expect { described_class.link_from_oauth_token(new_oauth_access_token) }
            .to raise_error(::Gitlab::Auth::Identity::IdentityLinkMismatchError)
        end
      end

      context 'when actor user does not have composite identity enforced' do
        before do
          allow(actor_user).to receive(:has_composite_identity?).and_return(false)
        end

        context 'when token has composite user scope' do
          it 'returns an identity' do
            expect(identity).not_to be_composite
            expect(identity).not_to be_linked
          end
        end

        context 'when token does not have composite user scope' do
          let_it_be(:token_scopes) { [:api] }
          let_it_be(:oauth_access_token) { create(:oauth_access_token, user: actor_user, scopes: token_scopes) }

          it 'returns an identity' do
            expect(identity).not_to be_composite
            expect(identity).not_to be_linked
          end
        end
      end
    end

    context 'when composite identity is not required for the actor' do
      it 'fabricates a valid identity' do
        expect(identity).not_to be_composite
        expect(identity).to be_valid
      end
    end
  end

  describe '.fabricate' do
    let_it_be(:user) { create(:user) }

    subject(:identity) { described_class.fabricate(user) }

    it 'returns a valid identity without a scoped user' do
      expect(identity).to be_valid

      expect { identity.scoped_user }
        .to raise_error(::Gitlab::Auth::Identity::MissingCompositeIdentityError)
    end
  end
end
