# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::OrganizationUsersService, feature_category: :organization do
  let_it_be_with_refind(:organization) { create(:organization, :confirmed) }

  subject(:service) { described_class.new(organization: organization) }

  describe '#execute' do
    context 'when organization is nil' do
      subject(:service) { described_class.new(organization: nil) }

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Organization is required')
      end
    end

    context 'when organization has already been activated' do
      let_it_be(:active_organization) { create(:organization) }

      subject(:service) { described_class.new(organization: active_organization) }

      it 'returns an error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Organization has already been activated')
      end
    end

    context 'when organization has no groups' do
      it 'returns success' do
        result = service.execute

        expect(result).to be_success
      end
    end

    context 'when organization has a single top-level group' do
      let_it_be(:single_tlg_org) { create(:organization, :confirmed) }
      let_it_be(:tlg_owner) { create(:user) }
      let_it_be(:tlg_developer) { create(:user) }
      let_it_be(:subgroup_only_owner) { create(:user) }
      let_it_be(:tlg) { create(:group, organization: single_tlg_org, owners: tlg_owner, developers: tlg_developer) }
      let_it_be(:subgroup) do
        create(:group, parent: tlg, organization: single_tlg_org, owners: subgroup_only_owner)
      end

      subject(:service) { described_class.new(organization: single_tlg_org) }

      it 'sets correct access levels for TLG members', :aggregate_failures do
        service.execute

        expect(single_tlg_org.organization_users.find_by(user: tlg_owner).access_level).to eq('owner')
        expect(single_tlg_org.organization_users.find_by(user: tlg_developer).access_level).to eq('default')
      end
    end

    context 'when organization has multiple top-level groups' do
      let_it_be(:both_tlg_owner) { create(:user) }
      let_it_be(:tlg1_only_owner) { create(:user) }
      let_it_be(:tlg2_only_owner) { create(:user) }
      let_it_be(:tlg1_developer) { create(:user) }
      let_it_be(:tlg1) do
        create(:group, organization: organization, owners: [both_tlg_owner, tlg1_only_owner],
          developers: tlg1_developer)
      end

      let_it_be(:tlg2) { create(:group, organization: organization, owners: [both_tlg_owner, tlg2_only_owner]) }

      it 'creates organization_user records with correct access levels based on ownership', :aggregate_failures do
        service.execute

        expect(organization.organization_users.find_by(user: both_tlg_owner).access_level).to eq('owner')

        expect(organization.organization_users.find_by(user: tlg1_only_owner).access_level).to eq('default')
        expect(organization.organization_users.find_by(user: tlg2_only_owner).access_level).to eq('default')

        expect(organization.organization_users.find_by(user: tlg1_developer).access_level).to eq('default')
      end
    end

    context 'when no users are owners of all TLGs' do
      let_it_be(:tlg1_owner) { create(:user) }
      let_it_be(:tlg2_owner) { create(:user) }
      let_it_be(:tlg1) { create(:group, organization: organization, owners: tlg1_owner) }
      let_it_be(:tlg2) { create(:group, organization: organization, owners: tlg2_owner) }

      it 'assigns default access level to all users' do
        service.execute

        expect(organization.organization_users.find_by(user: tlg1_owner).access_level).to eq('default')
        expect(organization.organization_users.find_by(user: tlg2_owner).access_level).to eq('default')
      end
    end

    context 'when TLG has invited members' do
      let_it_be(:invite_org) { create(:organization, :confirmed) }
      let_it_be(:tlg_owner) { create(:user) }
      let_it_be(:tlg) { create(:group, organization: invite_org, owners: tlg_owner) }
      let_it_be(:invited_member) { create(:group_member, :invited, source: tlg, access_level: Gitlab::Access::OWNER) }

      subject(:service) { described_class.new(organization: invite_org) }

      it 'excludes invited members from organization_users' do
        service.execute

        expect(invite_org.organization_users.pluck(:user_id)).to contain_exactly(tlg_owner.id)
      end
    end

    context 'when TLG has access requests' do
      let_it_be(:request_org) { create(:organization, :confirmed) }
      let_it_be(:tlg_owner) { create(:user) }
      let_it_be(:requesting_user) { create(:user) }
      let_it_be(:tlg) { create(:group, organization: request_org, owners: tlg_owner) }
      let_it_be(:access_request) do
        create(:group_member, :access_request, source: tlg, user: requesting_user, access_level: Gitlab::Access::OWNER)
      end

      subject(:service) { described_class.new(organization: request_org) }

      it 'excludes access requests from organization_users' do
        service.execute

        expect(request_org.organization_users.pluck(:user_id)).to contain_exactly(tlg_owner.id)
      end
    end
  end
end
