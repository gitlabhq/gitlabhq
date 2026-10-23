# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::OauthConsentGrants::CreateService, :aggregate_failures, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:application) do
    create(:oauth_application, :granular, boundary: Authz::Boundary.for(group), permissions: :read_group)
  end

  let(:source) { :doorkeeper }
  let(:service) { described_class.new(user: user, application: application, source: source, ip_address: '127.0.0.1') }

  before_all do
    instance_scope = build(:granular_scope, boundary: Authz::Boundary.for(:instance),
      permissions: [:create_member_role])
    create(:oauth_application_granular_scope, application: application, granular_scope: instance_scope)
  end

  subject(:response) { service.execute }

  def active_grants
    Authz::OauthConsentGrant.authorized.not_duo_session.for_user_and_application(user.id, application.id)
  end

  shared_examples 'records nothing' do
    it 'creates no rows, emits no audit event and schedules no token revocation' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
      expect(Authn::OauthApplications::RevokeNonGranularTokensWorker).not_to receive(:perform_async)

      expect { response }.to not_change { Authz::OauthConsentGrant.count }.and not_change { Authz::GranularScope.count }
    end
  end

  context 'when the granular_oauth_tokens feature flag is disabled' do
    before do
      stub_feature_flags(granular_oauth_tokens: false)
    end

    it { is_expected.to be_error.and have_attributes(reason: :feature_disabled) }

    it_behaves_like 'records nothing'
  end

  context 'with a duo_session source' do
    let(:source) { :duo_session }

    it { is_expected.to be_error.and have_attributes(reason: :unsupported_source) }

    it_behaves_like 'records nothing'
  end

  context 'when the application declares no granular scopes' do
    let_it_be(:application) { create(:oauth_application) }

    it { is_expected.to be_error.and have_attributes(reason: :no_granular_scopes) }

    it_behaves_like 'records nothing'
  end

  context 'on first consent' do
    it 'creates an authorized grant that copies the declared scopes into the user organization' do
      expect(response).to be_success

      grant = response.payload[:consent_grant]

      expect(grant).to be_persisted.and be_authorized
      expect(grant).to have_attributes(user: user, application: application, source: 'doorkeeper',
        organization_id: user.organization_id)
      expect(grant.granular_scopes.ids).not_to include(*application.granular_scopes.ids)
      expect(grant.granular_scopes).to contain_exactly(
        have_attributes(namespace_id: group.id, access: 'selected_memberships', permissions: ['read_group'],
          organization_id: user.organization_id),
        have_attributes(namespace_id: nil, access: 'instance', permissions: ['create_member_role'],
          organization_id: user.organization_id)
      )
      expect(grant.oauth_consent_grant_granular_scopes.map(&:organization_id)).to all(eq(user.organization_id))
      expect(response.payload[:previous_grant]).to be_nil
    end

    it 'schedules the revocation of the legacy tokens and codes' do
      expect(Authn::OauthApplications::RevokeNonGranularTokensWorker)
        .to receive(:perform_async).with(application.id, user.id)

      response
    end

    it 'emits a created audit event describing the copied scopes' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        name: 'oauth_consent_grant_created',
        author: user,
        scope: user,
        target: an_instance_of(Authz::OauthConsentGrant),
        target_details: application.name,
        message: 'User granted consent to an OAuth application.',
        additional_details: {
          application_id: application.id,
          application_name: application.name,
          application_owner_type: application.owner_type,
          application_owner_id: application.owner_id,
          source: 'doorkeeper',
          granular_scopes: contain_exactly(
            { 'access' => 'selected_memberships', 'namespace_id' => group.id, 'permissions' => ['read_group'] },
            { 'access' => 'instance', 'namespace_id' => nil, 'permissions' => ['create_member_role'] }
          )
        },
        ip_address: '127.0.0.1'
      )

      response
    end

    context 'with a trusted_auto_grant source' do
      let(:source) { :trusted_auto_grant }

      it 'records the source on the grant' do
        expect(response.payload[:consent_grant]).to be_trusted_auto_grant
      end
    end
  end

  context 'on a new consent while the active grant holds other scopes' do
    let_it_be_with_reload(:previous_grant) do
      create(:oauth_consent_grant, user: user, application: application,
        boundary: Authz::Boundary.for(:instance), permissions: :create_member_role)
    end

    let!(:granular_token) { create(:oauth_access_token, :granular, resource_owner: user, application: application) }

    it 'replaces the active grant with copies of the declared scopes and deletes the previous one' do
      copied_scope_ids = previous_grant.granular_scopes.ids
      declared_scope_ids = application.granular_scopes.ids

      expect(response).to be_success

      grant = response.payload[:consent_grant]

      expect(Authz::OauthConsentGrant.for_user_and_application(user.id, application.id)).to contain_exactly(grant)
      expect(grant.granular_scopes).to contain_exactly(
        have_attributes(namespace_id: group.id, access: 'selected_memberships', permissions: ['read_group']),
        have_attributes(namespace_id: nil, access: 'instance', permissions: ['create_member_role'])
      )
      expect(grant.granular_scopes.ids).not_to include(*declared_scope_ids)
      expect(Authz::GranularScope.where(id: copied_scope_ids)).to be_empty
      expect(Authz::GranularScope.where(id: declared_scope_ids).ids).to match_array(declared_scope_ids)
      expect(response.payload[:previous_grant]).to eq(previous_grant)
    end

    it 'leaves per-session grants untouched' do
      duo_session_grant = create(:oauth_consent_grant, user: user, application: application, source: :duo_session)

      response

      expect(duo_session_grant.reload).to be_authorized
    end

    it 'schedules the revocation of legacy tokens and codes, and granular tokens resolve the new grant' do
      expect(Authn::OauthApplications::RevokeNonGranularTokensWorker)
        .to receive(:perform_async).with(application.id, user.id)

      response

      expect(OauthAccessToken.find(granular_token.id).granular_scopes.map(&:permissions))
        .to contain_exactly(['read_group'], ['create_member_role'])
    end

    it 'emits an amended audit event referencing the replaced grant' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
        name: 'oauth_consent_grant_amended',
        message: 'User amended consent for an OAuth application.',
        additional_details: hash_including(previous_grant_id: previous_grant.id)
      ))

      response
    end

    context 'when a concurrent consent wins the race for the active grant' do
      before do
        allow(Authz::OauthConsentGrant).to receive(:authorized).and_return(Authz::OauthConsentGrant.none)
      end

      it 'returns a conflict and leaves the existing grant and tokens untouched' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
        expect(Authn::OauthApplications::RevokeNonGranularTokensWorker).not_to receive(:perform_async)

        expect { response }.not_to change { Authz::GranularScope.count }
        expect(response).to be_error.and have_attributes(reason: :conflict)
        expect(previous_grant.reload).to be_authorized
      end
    end

    context 'when the new grant cannot be saved' do
      before do
        allow_next_instance_of(Authz::OauthConsentGrant) do |grant|
          allow(grant).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(grant))
        end
      end

      it 'keeps the previous grant' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
        expect(Authn::OauthApplications::RevokeNonGranularTokensWorker).not_to receive(:perform_async)

        expect(response).to be_error.and have_attributes(reason: :invalid)
        expect(previous_grant.reload).to be_authorized
      end
    end
  end

  context 'on a new consent while the active grant holds the declared scopes' do
    let_it_be(:application) do
      create(:oauth_application, :granular, permissions: [:read_member_role, :create_member_role])
    end

    let_it_be_with_reload(:previous_grant) do
      create(:oauth_consent_grant, user: user, application: application,
        boundary: Authz::Boundary.for(:instance), permissions: [:read_member_role, :create_member_role])
    end

    let(:copied_scope) { previous_grant.granular_scopes.find_by!(access: :instance) }

    before_all do
      [
        build(:granular_scope, boundary: Authz::Boundary.for(group), permissions: [:read_group]),
        build(:granular_scope, boundary: Authz::Boundary.for(:user), permissions: [:create_personal_access_token])
      ].each do |declared_scope|
        create(:oauth_application_granular_scope, application: application, granular_scope: declared_scope)
        create(:oauth_consent_grant_granular_scope, oauth_consent_grant: previous_grant,
          granular_scope: declared_scope.build_copy.tap { |copy| copy.organization_id = user.organization_id })
      end
    end

    shared_examples 'keeps the active grant' do
      it 'returns the active grant without recording new rows or an audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        expect { response }.to not_change { Authz::OauthConsentGrant.ids }
          .and not_change { Authz::GranularScope.ids }
        expect(response).to be_success
        expect(response.payload).to eq(consent_grant: previous_grant, previous_grant: nil)
        expect(previous_grant.reload).to be_authorized
      end

      it 'still schedules the revocation of legacy tokens and codes minted while the flag was off' do
        expect(Authn::OauthApplications::RevokeNonGranularTokensWorker)
          .to receive(:perform_async).with(application.id, user.id)

        response
      end
    end

    it_behaves_like 'keeps the active grant'

    context 'when the copied permissions are in another order' do
      before do
        copied_scope.update_columns(permissions: %w[create_member_role read_member_role])
      end

      it_behaves_like 'keeps the active grant'
    end

    context 'when a copied scope attribute differs' do
      using RSpec::Parameterized::TableSyntax

      where(:attribute, :value) do
        :access       | 'user'
        :namespace_id | ref(:group_id)
        :permissions  | %w[read_member_role]
        :permissions  | %w[read_member_role create_member_role read_user]
      end

      with_them do
        let(:group_id) { group.id }

        before do
          copied_scope.update_columns(attribute => value)
        end

        it 'replaces the active grant' do
          expect(response).to be_success
          expect(response.payload[:previous_grant]).to eq(previous_grant)
          expect(Authz::OauthConsentGrant.exists?(previous_grant.id)).to be(false)
          expect(active_grants.sole).to eq(response.payload[:consent_grant])
        end
      end
    end

    context 'when the active grant was recorded from another source' do
      before do
        previous_grant.update_columns(source: Authz::OauthConsentGrant.sources[:trusted_auto_grant])
      end

      it 'replaces the active grant' do
        expect(response.payload[:previous_grant]).to eq(previous_grant)
        expect(response.payload[:consent_grant]).to be_doorkeeper
        expect(Authz::OauthConsentGrant.exists?(previous_grant.id)).to be(false)
      end
    end

    context 'when the active grant holds an extra copy of a declared scope' do
      before do
        create(:oauth_consent_grant_granular_scope, oauth_consent_grant: previous_grant,
          granular_scope: copied_scope.build_copy.tap(&:save!))
      end

      it 'replaces the active grant' do
        expect(response.payload[:previous_grant]).to eq(previous_grant)
        expect(Authz::OauthConsentGrant.exists?(previous_grant.id)).to be(false)
      end
    end
  end
end
