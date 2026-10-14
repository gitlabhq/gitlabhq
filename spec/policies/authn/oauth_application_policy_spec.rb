# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplicationPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:application) { create(:oauth_application, owner: user) }

  subject { described_class.new(current_user, application) }

  context 'when user is the owner' do
    let(:current_user) { user }

    it { expect_allowed(:read_oauth_application) }
    it { expect_allowed(:update_oauth_application) }
    it { expect_allowed(:delete_oauth_application) }
    it { expect_allowed(:update_oauth_application_granular_scope) }
  end

  context 'when user is not the owner' do
    let(:current_user) { other_user }

    it { expect_disallowed(:read_oauth_application) }
    it { expect_disallowed(:update_oauth_application) }
    it { expect_disallowed(:delete_oauth_application) }
    it { expect_disallowed(:update_oauth_application_granular_scope) }
  end

  describe 'update_oauth_application_granular_scope' do
    context 'with a user-owned application' do
      context 'when the user is an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it { expect_disallowed(:update_oauth_application_granular_scope) }
      end
    end

    context 'with a group-owned application' do
      let_it_be(:group) { create(:group) }
      let_it_be(:application) { create(:oauth_application, :group_owned, owner: group) }

      context 'when the user owns the group' do
        let_it_be(:current_user) { create(:user, owner_of: group) }

        it { expect_allowed(:update_oauth_application_granular_scope) }
      end

      context 'when the user maintains the group' do
        let_it_be(:current_user) { create(:user, maintainer_of: group) }

        it { expect_disallowed(:update_oauth_application_granular_scope) }
      end

      context 'when the user is an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it { expect_allowed(:update_oauth_application_granular_scope) }
      end
    end

    context 'with an instance application' do
      let_it_be(:application) { create(:oauth_application, :without_owner) }

      context 'when the user is an admin in admin mode', :enable_admin_mode do
        let(:current_user) { admin }

        it { expect_allowed(:update_oauth_application_granular_scope) }
      end

      context 'when the user is an admin outside admin mode' do
        let(:current_user) { admin }

        it { expect_disallowed(:update_oauth_application_granular_scope) }
      end

      context 'when the user is not an admin' do
        let(:current_user) { user }

        it { expect_disallowed(:update_oauth_application_granular_scope) }
      end

      context 'when there is no user' do
        let(:current_user) { nil }

        it { expect_disallowed(:read_oauth_application, :update_oauth_application_granular_scope) }
      end
    end

    context 'with a dynamically registered application', :enable_admin_mode do
      let_it_be(:application) { create(:oauth_application, :dynamic) }
      let(:current_user) { admin }

      it { expect_disallowed(:update_oauth_application_granular_scope) }
    end
  end
end
