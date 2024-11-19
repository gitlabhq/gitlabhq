# frozen_string_literal: true

RSpec.shared_examples 'resolves user solo-owned organizations' do
  context 'when user has no owned organizations' do
    it { is_expected.to be_empty }
  end

  context 'when user owns organizations' do
    let_it_be(:solo_owned_organizations) do
      create_list(:organization_owner, 2, user: organization_owner).map(&:organization)
    end

    let_it_be(:multi_owned_organization) do
      create(:organization, organization_users: [
        create(:organization_owner, user: organization_owner),
        create(:organization_owner, user: create(:user))
      ])
    end

    it 'returns solo-owned organizations' do
      is_expected.to match_array(solo_owned_organizations)
    end

    it 'does not return multi owned organizations' do
      is_expected.not_to include(multi_owned_organization)
    end
  end

  context 'when organization has other members' do
    let_it_be(:organization) do
      create(:organization, organization_users: [
        create(:organization_owner, user: organization_owner),
        create(:organization_user, user: create(:user))
      ])
    end

    it 'returns solo-owned organizations' do
      is_expected.to include(organization)
    end
  end
end
