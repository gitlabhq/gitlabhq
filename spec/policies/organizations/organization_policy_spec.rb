# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationPolicy, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_refind(:private_organization) { create(:organization, :private) }
  let_it_be_with_refind(:organization) { private_organization }
  let_it_be(:public_organization) { create(:organization, :public) }
  let_it_be(:default_organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the application code checks for default organization so we need to test this.
  let_it_be(:current_user) { create :user }

  subject(:policy) { described_class.new(current_user, organization) }

  context 'when the user is anonymous' do
    let_it_be(:current_user) { nil }

    it { expect_disallowed(:update_organization) }

    context 'when the organization is private' do
      it { expect_disallowed(:read_organization) }
      it { expect_disallowed(:read_artifact_registry) }
    end

    context 'when the organization is public' do
      let(:organization) { public_organization }

      it { expect_allowed(:read_organization) }
      it { expect_disallowed(:read_artifact_registry) }
    end
  end

  context 'when the user is an admin' do
    let_it_be(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { expect_allowed(:restore_organization) }

      it 'is granted the granular webhook abilities' do
        expect_allowed(:read_webhook, :create_webhook, :update_webhook, :delete_webhook, :test_webhook)
      end
    end

    context 'when admin mode is disabled' do
      it { expect_disallowed(:update_organization) }
      it { expect_disallowed(:restore_organization) }
      it { expect_disallowed(:access_organization_admin_area) }
      it { expect_disallowed(:read_user_groups) }
      it { expect_disallowed(:transfer_group) }
      it { expect_disallowed(:update_integration) }
      it { expect_disallowed(:read_artifact_registry) }
      it { expect_disallowed(:read_webhook, :create_webhook, :update_webhook, :delete_webhook, :test_webhook) }

      context 'when the organization is private' do
        it { expect_disallowed(:read_organization) }
      end

      context 'when the organization is public' do
        let_it_be(:organization) { public_organization }

        it { expect_allowed(:read_organization) }
        it { expect_disallowed(:read_artifact_registry) }
      end
    end
  end

  context 'when the user is part of the organization' do
    before_all do
      create(:organization_user, organization: organization, user: current_user)
    end

    it { expect_allowed(:create_group) }
  end

  context 'when the user is an owner of the organization' do
    before_all do
      create(:organization_user, :owner, organization: organization, user: current_user)
    end

    it { expect_allowed(:update_organization) }

    it 'is granted the granular webhook abilities' do
      expect_allowed(:read_webhook, :create_webhook, :update_webhook, :delete_webhook, :test_webhook)
    end
  end

  context 'when the user is not part of the organization' do
    it { expect_disallowed(:update_organization) }
    it { expect_disallowed(:create_group) }
    it { expect_disallowed(:delete_organization) }
    it { expect_disallowed(:restore_organization) }
    it { expect_disallowed(:read_organization_user) }
    it { expect_disallowed(:read_user_groups) }
    it { expect_disallowed(:read_artifact_registry) }
    it { expect_disallowed(:transfer_group) }
    it { expect_disallowed(:access_organization_admin_area) }
    it { expect_disallowed(:update_integration) }

    it 'is not granted any granular webhook ability' do
      expect_disallowed(:read_webhook, :create_webhook, :update_webhook, :delete_webhook, :test_webhook)
    end

    context 'when the organization is private' do
      it { expect_disallowed(:read_organization) }
    end

    context 'when the organization is public' do
      let_it_be(:organization) { public_organization }

      it { expect_allowed(:read_organization) }
      it { expect_disallowed(:read_artifact_registry) }
    end
  end

  context 'when the user is an owner but is blocked, deactivated, or inactive' do
    let(:current_user) { create(:user) }

    before do
      create(:organization_user, :owner, organization: organization, user: current_user)
    end

    context 'when the user is blocked' do
      before do
        current_user.block!
      end

      it { expect_disallowed(:delete_organization) }
      it { expect_disallowed(:restore_organization) }
    end

    context 'when the user is deactivated' do
      before do
        current_user.deactivate!
      end

      it { expect_disallowed(:delete_organization) }
      it { expect_disallowed(:restore_organization) }
    end

    context 'when the user is inactive (access locked)' do
      before do
        current_user.update!(locked_at: Time.current)
      end

      it { expect_disallowed(:delete_organization) }
      it { expect_disallowed(:restore_organization) }
    end
  end

  context 'when the organization is the default organization' do
    let(:organization) { default_organization }

    context 'when the user is an admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:user, :admin) }

      it { expect_disallowed(:delete_organization) }
    end

    context 'when the user is an owner of the organization' do
      before_all do
        Organizations::OrganizationUser
          .find_by!(organization: default_organization, user: current_user)
          .update!(access_level: :owner)
      end

      it { expect_disallowed(:delete_organization) }
    end
  end

  describe 'read_user_access_level' do
    let(:organization) { private_organization }

    let_it_be(:instance_admin) { create(:admin) }
    let_it_be(:non_member) { create(:user) }

    where(:user) do
      [ref(:instance_admin), ref(:non_member), nil]
    end

    with_them do
      let(:current_user) { user }

      it { expect_disallowed(:read_user_access_level) }
    end
  end
end
