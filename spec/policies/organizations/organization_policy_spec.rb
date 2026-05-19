# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationPolicy, feature_category: :organization do
  let_it_be_with_refind(:private_organization) { create(:organization, :private) }
  let_it_be_with_refind(:organization) { private_organization }
  let_it_be(:public_organization) { create(:organization, :public) }
  let_it_be(:default_organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the application code checks for default organization so we need to test this.
  let_it_be(:current_user) { create :user }

  subject(:policy) { described_class.new(current_user, organization) }

  context 'when the user is anonymous' do
    let_it_be(:current_user) { nil }

    it { is_expected.to be_disallowed(:admin_organization) }

    context 'when the organization is private' do
      it { is_expected.to be_disallowed(:read_organization) }
      it { is_expected.to be_disallowed(:read_artifact_registry) }
    end

    context 'when the organization is public' do
      let(:organization) { public_organization }

      it { is_expected.to be_allowed(:read_organization) }
      it { is_expected.to be_disallowed(:read_artifact_registry) }
    end
  end

  context 'when the user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(:admin_organization) }
      it { is_expected.to be_allowed(:create_group) }
      it { is_expected.to be_allowed(:delete_organization) }
      it { is_expected.to be_allowed(:read_organization) }
      it { is_expected.to be_allowed(:read_organization_user) }
      it { is_expected.to be_allowed(:read_artifact_registry) }
      it { expect_allowed(:transfer_group) }
      it { expect_allowed(:access_organization_admin_area) }

      context 'when org_admin_area feature flag is disabled' do
        before do
          stub_feature_flags(org_admin_area: false)
        end

        it { is_expected.to be_disallowed(:access_organization_admin_area) }
      end
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(:admin_organization) }
      it { is_expected.to be_disallowed(:access_organization_admin_area) }
      it { expect_disallowed(:transfer_group) }
      it { is_expected.to be_disallowed(:read_artifact_registry) }

      context 'when the organization is private' do
        it { is_expected.to be_disallowed(:read_organization) }
      end

      context 'when the organization is public' do
        let_it_be(:organization) { public_organization }

        it { is_expected.to be_allowed(:read_organization) }
        it { is_expected.to be_disallowed(:read_artifact_registry) }
      end
    end
  end

  context 'when the user is part of the organization' do
    before_all do
      create(:organization_user, organization: organization, user: current_user)
    end

    it { is_expected.to be_disallowed(:admin_organization) }
    it { is_expected.to be_allowed(:create_group) }
    it { is_expected.to be_disallowed(:delete_organization) }
    it { is_expected.to be_allowed(:read_organization) }
    it { is_expected.to be_allowed(:read_artifact_registry) }
    it { is_expected.to be_disallowed(:read_organization_user) }
    it { expect_disallowed(:transfer_group) }
    it { expect_disallowed(:access_organization_admin_area) }
  end

  context 'when the user is an owner of the organization' do
    before_all do
      create(:organization_user, :owner, organization: organization, user: current_user)
    end

    it { is_expected.to be_allowed(:admin_organization) }
    it { is_expected.to be_allowed(:create_group) }
    it { is_expected.to be_allowed(:delete_organization) }
    it { is_expected.to be_allowed(:read_organization) }
    it { is_expected.to be_allowed(:read_organization_user) }
    it { is_expected.to be_allowed(:read_artifact_registry) }
    it { expect_allowed(:transfer_group) }
    it { expect_allowed(:access_organization_admin_area) }

    context 'when org_admin_area feature flag is disabled' do
      before do
        stub_feature_flags(org_admin_area: false)
      end

      it { expect_disallowed(:access_organization_admin_area) }
    end
  end

  context 'when the user is not part of the organization' do
    it { is_expected.to be_disallowed(:admin_organization) }
    it { is_expected.to be_disallowed(:create_group) }
    it { is_expected.to be_disallowed(:delete_organization) }
    it { is_expected.to be_disallowed(:read_organization_user) }
    it { is_expected.to be_disallowed(:read_artifact_registry) }
    it { expect_disallowed(:transfer_group) }
    it { expect_disallowed(:access_organization_admin_area) }

    context 'when the organization is private' do
      it { is_expected.to be_disallowed(:read_organization) }
    end

    context 'when the organization is public' do
      let_it_be(:organization) { public_organization }

      it { is_expected.to be_allowed(:read_organization) }
      it { is_expected.to be_disallowed(:read_artifact_registry) }
    end
  end

  context 'when the organization is the default organization' do
    let(:organization) { default_organization }

    context 'when the user is an admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:user, :admin) }

      it { is_expected.to be_disallowed(:delete_organization) }
    end

    context 'when the user is an owner of the organization' do
      before_all do
        Organizations::OrganizationUser
          .find_by!(organization: default_organization, user: current_user)
          .update!(access_level: :owner)
      end

      it { is_expected.to be_disallowed(:delete_organization) }
    end
  end
end
