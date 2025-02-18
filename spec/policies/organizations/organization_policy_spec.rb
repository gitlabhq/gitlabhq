# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationPolicy, feature_category: :cell do
  let_it_be_with_refind(:private_organization) { create(:organization, :private) }
  let_it_be_with_refind(:organization) { private_organization }
  let_it_be(:public_organization) { create(:organization, :public) }
  let_it_be(:current_user) { create :user }

  subject(:policy) { described_class.new(current_user, organization) }

  context 'when the user is anonymous' do
    let_it_be(:current_user) { nil }

    it { is_expected.to be_disallowed(:admin_organization) }

    context 'when the organization is private' do
      it { is_expected.to be_disallowed(:read_organization) }
    end

    context 'when the organization is public' do
      let(:organization) { public_organization }

      it { is_expected.to be_allowed(:read_organization) }
    end
  end

  context 'when the user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(:admin_organization) }
      it { is_expected.to be_allowed(:create_group) }
      it { is_expected.to be_allowed(:read_organization) }
      it { is_expected.to be_allowed(:read_organization_user) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(:admin_organization) }

      context 'when the organization is private' do
        it { is_expected.to be_disallowed(:read_organization) }
      end

      context 'when the organization is public' do
        let_it_be(:organization) { public_organization }

        it { is_expected.to be_allowed(:read_organization) }
      end
    end
  end

  context 'when the user is part of the organization' do
    before_all do
      create(:organization_user, organization: organization, user: current_user)
    end

    it { is_expected.to be_disallowed(:admin_organization) }
    it { is_expected.to be_allowed(:create_group) }
    it { is_expected.to be_allowed(:read_organization) }
    it { is_expected.to be_disallowed(:read_organization_user) }
  end

  context 'when the user is an owner of the organization' do
    before_all do
      create(:organization_user, :owner, organization: organization, user: current_user)
    end

    it { is_expected.to be_allowed(:admin_organization) }
    it { is_expected.to be_allowed(:create_group) }
    it { is_expected.to be_allowed(:read_organization) }
    it { is_expected.to be_allowed(:read_organization_user) }
  end

  context 'when the user is not part of the organization' do
    it { is_expected.to be_disallowed(:admin_organization) }
    it { is_expected.to be_disallowed(:create_group) }
    it { is_expected.to be_disallowed(:read_organization_user) }

    context 'when the organization is private' do
      it { is_expected.to be_disallowed(:read_organization) }
    end

    context 'when the organization is public' do
      let_it_be(:organization) { public_organization }

      it { is_expected.to be_allowed(:read_organization) }
    end
  end
end
