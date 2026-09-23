# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Organizations::GrantOwnerRoleWorker, feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:actor) { create(:user, organization: organization, owner_of: organization) }
  let_it_be(:user) { create(:user, organization: organization) }

  let(:job_args) { [organization.id, user.id, actor.id] }
  let(:token) { 'ar-token' }
  let(:data_access_audience) { Authn::TokenExchange::TokenIssuer::DATA_ACCESS_AUDIENCE }
  let(:client) { instance_double(Authn::IamService::UpdateRelationshipsClient) }

  before_all do
    Organizations::OrganizationUser.find_by!(organization: organization, user: user).update!(access_level: :owner)
  end

  before do
    issuer = instance_double(Authn::TokenExchange::TokenIssuer, token: token)
    allow(Authn::TokenExchange::TokenIssuer).to receive(:new).and_return(issuer)

    allow(Authn::IamService::UpdateRelationshipsClient).to receive(:new).and_return(client)
    allow(client).to receive(:grant_roles).and_return(::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new)
  end

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { described_class.new.perform(organization.id, user.id, actor.id) }

    it 'grants the organization_admin role, minting the token as the acting owner' do
      expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
        .with(audiences: [data_access_audience], user: actor, organization: organization)
        .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

      expect(client).to receive(:grant_roles) do |inputs, organization_uuid:, token:|
        expect(token).to eq('ar-token')
        expect(organization_uuid).to eq(organization.uuid)
        expect(inputs).to contain_exactly(
          assignee_id: user.id,
          resource_id: organization.uuid,
          role_id: Authz::Organizations::Roles.organization_admin_uuid
        )

        ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
      end

      perform
    end

    context 'when no actor is given' do
      subject(:perform) { described_class.new.perform(organization.id, user.id) }

      it 'falls back to minting the token as the owner being granted the role' do
        expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
          .with(audiences: [data_access_audience], user: user, organization: organization)
          .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

        expect(client).to receive(:grant_roles)

        perform
      end
    end

    context 'when the actor is no longer an owner of this organization' do
      subject(:perform) { described_class.new.perform(organization.id, user.id, actor.id) }

      before do
        Organizations::OrganizationUser.find_by!(organization: organization, user: actor)
          .update!(access_level: :default)
      end

      it 'falls back to minting the token as the owner being granted the role' do
        expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
          .with(audiences: [data_access_audience], user: user, organization: organization)
          .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

        expect(client).to receive(:grant_roles)

        perform
      end
    end

    context 'when the organization cannot be found' do
      before do
        allow(Organizations::Organization).to receive(:find_by_id).with(organization.id).and_return(nil)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:grant_roles)

        perform
      end
    end

    context 'when the user cannot be found' do
      before do
        allow(User).to receive(:find_by_id).with(user.id).and_return(nil)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:grant_roles)

        perform
      end
    end

    context 'when the owner is a member of the organization but not homed there' do
      let_it_be(:promoted_organization) { create(:organization) }
      let_it_be(:promoted_actor) { create(:user, organization: promoted_organization, owner_of: promoted_organization) }

      before_all do
        create(:organization_user, organization: promoted_organization, user: user, access_level: :owner)
      end

      subject(:perform) { described_class.new.perform(promoted_organization.id, user.id, promoted_actor.id) }

      it 'grants the role for the promoted organization, not the home organization' do
        expect(client).to receive(:grant_roles) do |inputs, organization_uuid:, token:|
          expect(token).to eq('ar-token')
          expect(organization_uuid).to eq(promoted_organization.uuid)
          expect(inputs).to contain_exactly(
            assignee_id: user.id,
            resource_id: promoted_organization.uuid,
            role_id: Authz::Organizations::Roles.organization_admin_uuid
          )

          ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
        end

        perform
      end
    end

    context 'when the user is not a member of this organization at all' do
      let_it_be(:other_organization) { create(:organization) }

      subject(:perform) { described_class.new.perform(other_organization.id, user.id, actor.id) }

      it 'does not call IAM' do
        expect(client).not_to receive(:grant_roles)

        perform
      end
    end

    context 'when the user is no longer an owner of this organization' do
      before do
        # update_columns bypasses the last-owner validation - this is test
        # setup for a state the app itself keeps intact (another owner must
        # always remain), not a scenario under test here.
        Organizations::OrganizationUser.find_by!(organization: organization, user: user)
          .update_columns(access_level: Gitlab::Access::GUEST)
      end

      it 'does not call IAM' do
        expect(client).not_to receive(:grant_roles)

        perform
      end
    end

    context 'when the grant fails with a retryable reason' do
      %i[unavailable timeout unknown unauthenticated].each do |reason|
        it "raises to trigger a Sidekiq retry for #{reason}" do
          allow(client).to receive(:grant_roles).and_raise(
            Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: reason)
          )

          expect { perform }.to raise_error(Authz::Organizations::GrantOwnerRoleWorker::RequestError)
        end
      end
    end

    context 'when the grant fails with a non-retryable reason' do
      before do
        allow(client).to receive(:grant_roles).and_raise(
          Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: :permission_denied)
        )
      end

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end
  end
end
