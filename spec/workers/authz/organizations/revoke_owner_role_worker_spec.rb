# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Organizations::RevokeOwnerRoleWorker, feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:actor) { create(:user, organization: organization, owner_of: organization) }
  let_it_be(:user) { create(:user, organization: organization) }

  let(:job_args) { [organization.id, user.id, actor.id] }

  let(:token) { 'ar-token' }
  let(:data_access_audience) { Authn::TokenExchange::TokenIssuer::DATA_ACCESS_AUDIENCE }
  let(:client) { instance_double(Authn::IamService::UpdateRelationshipsClient) }

  before do
    issuer = instance_double(Authn::TokenExchange::TokenIssuer, token: token)
    allow(Authn::TokenExchange::TokenIssuer).to receive(:new).and_return(issuer)

    allow(Authn::IamService::UpdateRelationshipsClient).to receive(:new).and_return(client)
    allow(client).to receive(:revoke_roles).and_return(::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new)
  end

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { described_class.new.perform(organization.id, user.id, actor.id) }

    # Asserting the exact user: argument is what would have caught the
    # demoted-subject regression this test exists for.
    it 'revokes the role, minting the token as the acting owner rather than the demoted user' do
      expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
        .with(audiences: [data_access_audience], user: actor, organization: organization)
        .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

      expect(client).to receive(:revoke_roles) do |keys, organization_uuid:, token:|
        expect(token).to eq('ar-token')
        expect(organization_uuid).to eq(organization.uuid)
        expect(keys).to contain_exactly(assignee_id: user.id, resource_id: organization.uuid)

        ::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new
      end

      perform
    end

    shared_examples 'revokes the role as the user themselves' do
      it 'revokes the role, minting the token as the user themselves' do
        expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
          .with(audiences: [data_access_audience], user: user, organization: organization)
          .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

        expect(client).to receive(:revoke_roles) do |keys, organization_uuid:, token:|
          expect(token).to eq('ar-token')
          expect(organization_uuid).to eq(organization.uuid)
          expect(keys).to contain_exactly(assignee_id: user.id, resource_id: organization.uuid)

          ::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new
        end

        perform
      end
    end

    shared_examples 'logs the requested actor' do
      it 'logs that the user revoked their own role instead of the requested actor' do
        allow(Gitlab::AppLogger).to receive(:info)
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          'message' => 'Organization admin role revoked as the user because no owner was available to act as',
          Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
          Labkit::Fields::GL_USER_ID => user.id,
          'requested_actor_id' => requested_actor_id
        ))

        perform
      end
    end

    context 'when the actor is the user themselves (e.g. leaving the organization)' do
      subject(:perform) { described_class.new.perform(organization.id, user.id, user.id) }

      it_behaves_like 'revokes the role as the user themselves'

      it 'does not log a requested actor' do
        allow(Gitlab::AppLogger).to receive(:info)
        expect(Gitlab::AppLogger).not_to receive(:info).with(hash_including('requested_actor_id' => anything))

        perform
      end
    end

    context 'when no actor is given' do
      let(:requested_actor_id) { nil }

      subject(:perform) { described_class.new.perform(organization.id, user.id) }

      it_behaves_like 'revokes the role as the user themselves'
      it_behaves_like 'logs the requested actor'
    end

    # The usual case when an instance admin demotes an owner from the Admin Area.
    context 'when the actor is an instance admin who does not own this organization' do
      let_it_be(:admin) { create(:admin) }
      let(:requested_actor_id) { admin.id }

      subject(:perform) { described_class.new.perform(organization.id, user.id, admin.id) }

      it_behaves_like 'revokes the role as the user themselves'
      it_behaves_like 'logs the requested actor'
    end

    context 'when the actor is no longer an owner of this organization' do
      let(:requested_actor_id) { actor.id }

      before do
        # update_columns bypasses the last-owner validation, since actor is
        # the only owner here and this state is just standing in for the
        # actor going stale by any means between enqueue and execution.
        Organizations::OrganizationUser.find_by!(organization: organization, user: actor)
          .update_columns(access_level: Gitlab::Access::GUEST)
      end

      it_behaves_like 'revokes the role as the user themselves'
      it_behaves_like 'logs the requested actor'
    end

    context 'when the organization cannot be found' do
      before do
        allow(Organizations::Organization).to receive(:find_by_id).with(organization.id).and_return(nil)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:revoke_roles)

        perform
      end
    end

    context 'when the user cannot be found' do
      before do
        allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:revoke_roles)

        perform
      end
    end

    context 'when the former owner is a member of the organization but not homed there' do
      let_it_be(:promoted_organization) { create(:organization) }
      let_it_be(:promoted_actor) { create(:user, organization: promoted_organization, owner_of: promoted_organization) }

      let_it_be(:promoted_membership) do
        create(:organization_user, organization: promoted_organization, user: user, access_level: :default)
      end

      subject(:perform) { described_class.new.perform(promoted_organization.id, user.id, promoted_actor.id) }

      it 'revokes the role for the promoted organization, not the home organization' do
        expect(client).to receive(:revoke_roles) do |keys, organization_uuid:, token:|
          expect(token).to eq('ar-token')
          expect(organization_uuid).to eq(promoted_organization.uuid)
          expect(keys).to contain_exactly(assignee_id: user.id, resource_id: promoted_organization.uuid)

          ::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new
        end

        perform
      end
    end

    # A user with no membership is also not an owner, so they revoke as
    # themselves and IAM answers :not_found when nothing was granted.
    context 'when the user is not a member of this organization at all' do
      let_it_be(:other_organization) { create(:organization) }

      subject(:perform) { described_class.new.perform(other_organization.id, user.id) }

      it 'revokes as the user for that organization' do
        expect(client).to receive(:revoke_roles) do |keys, organization_uuid:, **|
          expect(organization_uuid).to eq(other_organization.uuid)
          expect(keys).to contain_exactly(assignee_id: user.id, resource_id: other_organization.uuid)

          ::Gitlab::Iam::Update::V1::DeleteRelationshipsResponse.new
        end

        perform
      end
    end

    context 'when the user is an owner of this organization again' do
      before do
        Organizations::OrganizationUser.find_by!(organization: organization, user: user).update!(access_level: :owner)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:revoke_roles)

        perform
      end
    end

    context 'when the revocation fails because the subject was never granted anything' do
      before do
        allow(client).to receive(:revoke_roles).and_raise(
          Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: :not_found)
        )
      end

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when the revocation fails with a retryable reason' do
      %i[unavailable timeout unknown unauthenticated].each do |reason|
        it "raises to trigger a Sidekiq retry for #{reason}" do
          allow(client).to receive(:revoke_roles).and_raise(
            Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: reason)
          )

          expect { perform }.to raise_error(Authz::Organizations::RevokeOwnerRoleWorker::RequestError)
        end
      end
    end

    context 'when the revocation fails with a non-retryable reason' do
      before do
        allow(client).to receive(:revoke_roles).and_raise(
          Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: :permission_denied)
        )
      end

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end
  end
end
