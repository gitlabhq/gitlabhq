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
      subject(:perform) { described_class.new.perform(organization.id, non_existing_record_id, actor.id) }

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

    context 'when the owner is an instance admin' do
      let_it_be(:admin_owner) { create(:admin, organization: organization, owner_of: organization) }

      context 'when the owner row is on their home organization' do
        subject(:perform) { described_class.new.perform(organization.id, admin_owner.id, actor.id) }

        it 'does not call IAM, since the row comes from the admin flag' do
          expect(client).not_to receive(:grant_roles)

          perform
        end
      end

      context 'when the owner row is on another organization' do
        let_it_be(:other_organization) { create(:organization) }

        subject(:perform) { described_class.new.perform(other_organization.id, admin_owner.id) }

        before_all do
          create(:organization_user, organization: other_organization, user: admin_owner, access_level: :owner)
        end

        it 'grants the role like any other owner' do
          expect(client).to receive(:grant_roles) do |inputs, organization_uuid:, **|
            expect(organization_uuid).to eq(other_organization.uuid)
            expect(inputs.map { |input| input[:assignee_id] }).to contain_exactly(admin_owner.id)

            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end

          perform
        end
      end
    end

    context 'when no user is given' do
      subject(:perform) { described_class.new.perform(organization.id, nil, actor.id) }

      context 'when one of the owners is an instance admin homed on this organization' do
        let_it_be(:admin_owner) { create(:admin, organization: organization, owner_of: organization) }

        it 'grants the other owners only' do
          expect(client).to receive(:grant_roles) do |inputs, **|
            expect(inputs.map { |input| input[:assignee_id] }).to contain_exactly(actor.id, user.id)

            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end

          perform
        end

        context 'when that admin is the acting user' do
          subject(:perform) { described_class.new.perform(organization.id, nil, admin_owner.id) }

          it 'mints the token as the admin but leaves them out of the grant', :aggregate_failures do
            expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
              .with(audiences: [data_access_audience], user: admin_owner, organization: organization)
              .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

            expect(client).to receive(:grant_roles) do |inputs, **|
              expect(inputs.map { |input| input[:assignee_id] }).to contain_exactly(actor.id, user.id)

              ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
            end

            perform
          end
        end
      end

      context 'when one of the owners is an instance admin homed elsewhere' do
        let_it_be(:admin_owner) { create(:admin) }

        before_all do
          create(:organization_user, organization: organization, user: admin_owner, access_level: :owner)
        end

        it 'grants them along with the other owners' do
          expect(client).to receive(:grant_roles) do |inputs, **|
            expect(inputs.map { |input| input[:assignee_id] }).to contain_exactly(actor.id, user.id, admin_owner.id)

            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end

          perform
        end
      end

      context 'when the owners span several batches' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'makes one IAM call per batch' do
          granted = []
          expect(client).to receive(:grant_roles).twice do |inputs, **|
            granted.concat(inputs.map { |input| input[:assignee_id] })
            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end

          perform

          expect(granted).to contain_exactly(actor.id, user.id)
        end

        it 'raises for a retryable failure so the whole job retries' do
          allow(client).to receive(:grant_roles).and_raise(
            Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: :unavailable)
          )

          expect { perform }.to raise_error(described_class::RequestError)
        end

        it 'logs a non-retryable failure and still processes the remaining batches', :aggregate_failures do
          denied = Authn::IamService::UpdateRelationshipsClient::RequestError
            .new('diagnostic', reason: :permission_denied)
          calls = 0
          allow(client).to receive(:grant_roles) do
            calls += 1
            raise denied if calls == 1

            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end
          expect(Gitlab::AppLogger).to receive(:error).with(hash_including(Labkit::Fields::GL_USER_ID => actor.id))

          expect { perform }.not_to raise_error
          expect(calls).to eq(2)
        end
      end

      context 'when a whole batch fails with a non-retryable reason' do
        before do
          allow(client).to receive(:grant_roles).and_raise(
            Authn::IamService::UpdateRelationshipsClient::RequestError.new('diagnostic', reason: :permission_denied)
          )
        end

        it 'logs the failure once per owner in the batch', :aggregate_failures do
          expect(Gitlab::AppLogger).to receive(:error).with(hash_including(Labkit::Fields::GL_USER_ID => actor.id))
          expect(Gitlab::AppLogger).to receive(:error).with(hash_including(Labkit::Fields::GL_USER_ID => user.id))

          expect { perform }.not_to raise_error
        end
      end

      it 'grants every current owner in one IAM call, minting the token as the acting owner', :aggregate_failures do
        expect(Authn::TokenExchange::TokenIssuer).to receive(:new)
          .with(audiences: [data_access_audience], user: actor, organization: organization)
          .and_return(instance_double(Authn::TokenExchange::TokenIssuer, token: token))

        expect(client).to receive(:grant_roles) do |inputs, organization_uuid:, token:|
          expect(token).to eq('ar-token')
          expect(organization_uuid).to eq(organization.uuid)
          expect(inputs.map { |input| input[:assignee_id] }).to contain_exactly(actor.id, user.id)
          expect(inputs.map { |input| input[:resource_id] }).to all(eq(organization.uuid))

          ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
        end

        perform
      end

      context 'when the acting user is not an owner of this organization' do
        let_it_be(:member) { create(:user, organization: organization) }

        subject(:perform) { described_class.new.perform(organization.id, nil, member.id) }

        it 'grants the batch with a token minted as one of its owners instead of skipping', :aggregate_failures do
          minted_for = []
          allow(Authn::TokenExchange::TokenIssuer).to receive(:new) do |user:, **|
            minted_for << user
            instance_double(Authn::TokenExchange::TokenIssuer, token: token)
          end
          granted = []
          expect(client).to receive(:grant_roles).once do |inputs, **|
            granted.concat(inputs.map { |input| input[:assignee_id] })
            ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
          end

          perform

          expect(granted).to contain_exactly(actor.id, user.id)
          expect(minted_for.size).to eq(1)
          expect([actor, user]).to include(minted_for.first)
        end
      end

      context 'when the organization cannot be found' do
        subject(:perform) { described_class.new.perform(non_existing_record_id, nil, actor.id) }

        it 'does not call IAM' do
          expect(client).not_to receive(:grant_roles)

          perform
        end
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
