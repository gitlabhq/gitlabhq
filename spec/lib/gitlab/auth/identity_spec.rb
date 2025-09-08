# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Identity, :request_store, feature_category: :system_access do
  let_it_be_with_reload(:primary_user) { create(:user, :service_account) }
  let_it_be(:scoped_user) { create(:user) }

  describe '.link_from_oauth_token' do
    let_it_be(:token_scopes) { [:api, :"user:#{scoped_user.id}"] }
    let_it_be(:oauth_access_token) { create(:oauth_access_token, user: primary_user, scopes: token_scopes) }

    subject(:identity) { described_class.link_from_oauth_token(oauth_access_token) }

    context 'when composite identity is required for the actor' do
      before do
        primary_user.update!(composite_identity_enforced: true)
      end

      it 'returns an identity' do
        expect(identity).to be_composite
        expect(identity).to be_linked
        expect(identity).to be_valid

        expect(identity.scoped_user).to eq(scoped_user)
      end

      context 'when oauth token does not have required scopes' do
        let(:oauth_access_token) { create(:oauth_access_token, user: primary_user, scopes: [:api]) }

        it 'fabricates a composite identity which is not valid' do
          expect(identity).to be_composite
          expect(identity).not_to be_linked
          expect(identity).not_to be_valid
        end
      end

      context 'when an identity link was already done for a different composite user' do
        let_it_be(:different_user) { create(:user) }
        let_it_be(:new_token_scopes) { [:api, :"user:#{different_user.id}"] }
        let_it_be(:new_oauth_access_token) do
          create(:oauth_access_token, user: primary_user, scopes: new_token_scopes)
        end

        it 'raises an error' do
          expect(identity).to be_valid

          expect { described_class.link_from_oauth_token(new_oauth_access_token) }
            .to raise_error(::Gitlab::Auth::Identity::IdentityLinkMismatchError)
        end
      end

      context 'when actor user does not have composite identity enforced' do
        before do
          primary_user.update!(composite_identity_enforced: false)
        end

        context 'when token has composite user scope' do
          it 'returns a valid, non-composite identity' do
            expect(identity).to be_valid
            expect(identity).not_to be_composite
            expect(identity).not_to be_linked
          end
        end

        context 'when token does not have composite user scope' do
          let_it_be(:token_scopes) { [:api] }
          let_it_be(:oauth_access_token) do
            create(:oauth_access_token, user: primary_user, scopes: token_scopes)
          end

          it 'returns a valid, non-composite identity' do
            expect(identity).to be_valid
            expect(identity).not_to be_composite
            expect(identity).not_to be_linked
          end
        end
      end
    end
  end

  describe '.link_from_scoped_user_id' do
    let(:scoped_user_id) { scoped_user.id }

    subject(:identity) { described_class.link_from_scoped_user_id(primary_user, scoped_user_id) }

    context 'when composite identity is required for the actor' do
      before do
        primary_user.update!(composite_identity_enforced: true)
      end

      it 'returns an identity' do
        expect(identity).to be_composite
        expect(identity).to be_linked
        expect(identity).to be_valid

        expect(identity.scoped_user).to eq(scoped_user)
      end
    end

    context 'when scoped_user_id is unknown' do
      let(:scoped_user_id) { 0 }

      it 'returns nil' do
        expect(identity).to be_nil
      end
    end
  end

  describe '.find_primary_user_by_scoped_user_id' do
    let(:scoped_user_id) { scoped_user.id }

    subject(:found_primary_user) { described_class.find_primary_user_by_scoped_user_id(scoped_user_id) }

    context 'when a composite identity is linked' do
      before do
        primary_user.update!(composite_identity_enforced: true)
        described_class.link_from_scoped_user_id(primary_user, scoped_user_id)
      end

      it 'returns the primary user' do
        expect(found_primary_user).to eq(primary_user)
      end
    end

    context 'when no composite identity is linked for the scoped user' do
      it 'returns nil' do
        expect(found_primary_user).to be_nil
      end
    end

    context 'when scoped_user_id is nil' do
      let(:scoped_user_id) { nil }

      it 'returns nil' do
        expect(found_primary_user).to be_nil
      end
    end

    context 'when scoped_user_id does not exist' do
      let(:scoped_user_id) { 99999 }

      before do
        primary_user.update!(composite_identity_enforced: true)
        described_class.link_from_scoped_user_id(primary_user, scoped_user.id)
      end

      it 'returns nil' do
        expect(found_primary_user).to be_nil
      end
    end
  end

  describe '.fabricate' do
    subject(:identity) { described_class.fabricate(primary_user) }

    it 'returns a valid identity without a scoped user' do
      expect(identity).to be_valid

      expect { identity.scoped_user }
        .to raise_error(::Gitlab::Auth::Identity::MissingCompositeIdentityError)
    end
  end

  describe '.link_from_web_request' do
    context 'when service_account has composite identity enforced' do
      before do
        primary_user.update!(composite_identity_enforced: true)
      end

      it 'creates and links identity with scope user' do
        identity = described_class.link_from_web_request(
          service_account: primary_user,
          scoped_user: scoped_user
        )

        expect(identity.primary_user).to eq(primary_user)
        expect(identity.scoped_user).to eq(scoped_user)
        expect(identity).to be_linked
      end

      context 'when trying to link different scoped users' do
        let(:another_scope_user) { create(:user) }

        it 'raises IdentityLinkMismatchError when trying to link different scoped users' do
          identity = described_class.link_from_web_request(
            service_account: primary_user,
            scoped_user: scoped_user
          )

          expect do
            identity.link!(another_scope_user)
          end.to raise_error(described_class::IdentityLinkMismatchError)
        end
      end

      context 'when service_account does not have composite identity enforced' do
        before do
          primary_user.update!(composite_identity_enforced: false)
        end

        it 'creates identity without linking' do
          identity = described_class.link_from_web_request(
            service_account: primary_user,
            scoped_user: scoped_user
          )

          expect(identity).not_to be_linked
        end
      end

      context 'when service_account is not present' do
        it 'raises an error' do
          expect do
            described_class.link_from_web_request(
              service_account: nil,
              scoped_user: scoped_user
            )
          end.to raise_error(described_class::MissingServiceAccountError)
        end
      end
    end
  end

  describe '#valid?' do
    context 'when a composite identity is linked to another composite identity' do
      before do
        primary_user.update!(composite_identity_enforced: true)
        scoped_user.composite_identity_enforced!
      end

      it 'is not valid' do
        identity = described_class.fabricate(primary_user)
        identity.link!(scoped_user)

        expect(identity).not_to be_valid
      end
    end
  end

  describe '.sidekiq_restore!' do
    context 'when job has primary and scoped identity stored' do
      let(:job) { { 'jid' => 123, 'sqci' => [primary_user.id, scoped_user.id] } }

      it 'finds and links primary user with scoped user' do
        identity = described_class.sidekiq_restore!(job)

        expect(identity).to be_linked
        expect(identity.primary_user).to eq(primary_user)
        expect(identity.scoped_user).to eq(scoped_user)
      end
    end

    context 'when linked identity in job is an unexpected value' do
      let(:job) { { 'jid' => 123, 'sqci' => [primary_user.id] } }

      it 'finds and links primary user with scoped user' do
        expect { described_class.sidekiq_restore!(job) }
          .to raise_error(described_class::IdentityError)
      end
    end
  end

  describe '#sidekiq_link!' do
    let(:job) { { 'jid' => 123 } }

    subject(:identity) { described_class.new(primary_user) }

    before do
      identity.link!(scoped_user)
    end

    it 'sets a job attribute' do
      described_class.new(primary_user).sidekiq_link!(job)

      expect(job[described_class::COMPOSITE_IDENTITY_SIDEKIQ_ARG])
        .to match_array([primary_user.id, scoped_user.id])
    end
  end

  describe '.invert_composite_identity' do
    subject(:result) { described_class.invert_composite_identity(current_user) }

    context 'when current_user is nil' do
      let(:current_user) { nil }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when current_user is a regular user' do
      let(:current_user) { create(:user) }

      it 'returns the original user' do
        expect(result).to eq(current_user)
      end

      context 'when no composite identity exists for the user' do
        before do
          allow(described_class).to receive(:find_primary_user_by_scoped_user_id)
                                      .with(current_user.id)
                                      .and_return(nil)
        end

        it 'returns the original user' do
          expect(result).to eq(current_user)
        end
      end
    end

    context 'when current_user is a scoped user in a composite identity' do
      let(:current_user) { scoped_user }

      before do
        primary_user.update!(composite_identity_enforced: true)
        described_class.link_from_scoped_user_id(primary_user, scoped_user.id)
      end

      it 'returns the primary user' do
        expect(result).to eq(primary_user)
      end
    end

    context 'when current_user is already a primary user' do
      let(:current_user) { primary_user }

      before do
        primary_user.update!(composite_identity_enforced: true)
        described_class.link_from_scoped_user_id(primary_user, scoped_user.id)
      end

      it 'returns the primary user itself' do
        expect(result).to eq(primary_user)
      end
    end

    context 'when request store is empty' do
      let(:current_user) { scoped_user }

      before do
        Gitlab::SafeRequestStore.clear!
      end

      it 'returns the original user when no composite identities are stored' do
        expect(result).to eq(current_user)
      end
    end
  end

  describe '#link!' do
    subject(:identity) { described_class.new(primary_user) }

    context 'when user has not been linked already' do
      it 'links primary identity to scoped identity' do
        expect(identity).not_to be_linked

        identity.link!(scoped_user)

        expect(identity).to be_linked
        expect(identity.scoped_user).to eq(scoped_user)
      end
    end

    context 'when primary user has already been linked' do
      let(:another_user) { create(:user) }

      before do
        identity.link!(scoped_user)
      end

      context 'when linking with another user' do
        it 'raises an exception' do
          expect { identity.link!(another_user) }
            .to raise_error(described_class::IdentityLinkMismatchError)
            .and not_change { identity.scoped_user }
        end
      end

      context 'when linking with the same user' do
        it 'is idempotent' do
          expect { identity.link!(scoped_user) }.not_to raise_error
        end
      end
    end

    it 'appends scoped user details to application structured log' do
      identity.link!(scoped_user)

      expect(Gitlab::ApplicationContext.current).to include({
        'meta.scoped_user' => scoped_user.username,
        'meta.scoped_user_id' => scoped_user.id
      })
    end
  end
end
