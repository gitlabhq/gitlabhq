# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokenPolicy do
  include AdminModeHelper

  subject { described_class.new(current_user, token) }

  context 'current_user is an administrator', :enable_admin_mode do
    let_it_be(:current_user) { build_stubbed(:admin) }

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_allowed(:revoke_personal_access_token) }
    end

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_allowed(:revoke_personal_access_token) }
    end
  end

  context 'current_user is not an administrator' do
    let_it_be(:current_user) { build_stubbed(:user) }

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_disallowed(:revoke_personal_access_token) }
    end

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_allowed(:revoke_personal_access_token) }
    end

    context 'subject of the impersonated token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user, impersonation: true) }

      it { is_expected.to be_disallowed(:revoke_personal_access_token) }
    end
  end

  context 'current_user is a blocked administrator', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin, :blocked) }

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_disallowed(:revoke_personal_access_token) }
    end

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_disallowed(:revoke_personal_access_token) }
    end
  end

  context "for a service account's token", feature_category: :user_management do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    shared_examples 'follows admin_service_accounts on the provisioning scope' do
      context 'when the actor owns the provisioning scope' do
        before do
          scope_owner.add_owner(current_user)
        end

        it { is_expected.to be_allowed(:revoke_personal_access_token) }

        context 'when the actor is blocked' do
          let(:current_user) { create(:user, :blocked) }

          it { is_expected.to be_disallowed(:revoke_personal_access_token) }
        end
      end

      context 'when the actor is not a member of the provisioning scope' do
        it { is_expected.to be_disallowed(:revoke_personal_access_token) }
      end
    end

    context 'group-provisioned' do
      let_it_be(:service_account) { create(:user, :service_account, provisioned_by_group: group) }
      let_it_be(:token) { create(:personal_access_token, user: service_account) }
      let(:current_user) { create(:user) }
      let(:scope_owner) { group }

      it_behaves_like 'follows admin_service_accounts on the provisioning scope'

      context 'when the actor is a group maintainer (no admin_service_accounts at group level)' do
        let_it_be(:maintainer) { create(:user) }
        let(:current_user) { maintainer }

        before_all do
          group.add_maintainer(maintainer)
        end

        it { is_expected.to be_disallowed(:revoke_personal_access_token) }
      end
    end

    context 'project-provisioned' do
      let_it_be(:service_account) { create(:user, :service_account, provisioned_by_project: project) }
      let_it_be(:token) { create(:personal_access_token, user: service_account) }
      let(:current_user) { create(:user) }
      let(:scope_owner) { project }

      it_behaves_like 'follows admin_service_accounts on the provisioning scope'

      context 'when the actor is a project maintainer (has admin_service_accounts at project level)' do
        let_it_be(:maintainer) { create(:user) }
        let(:current_user) { maintainer }

        before_all do
          project.add_maintainer(maintainer)
        end

        it { is_expected.to be_allowed(:revoke_personal_access_token) }
      end
    end

    context 'with no provisioning scope' do
      let_it_be(:service_account) { create(:user, :service_account) }
      let_it_be(:token) { create(:personal_access_token, user: service_account) }
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:revoke_personal_access_token) }
    end
  end
end
