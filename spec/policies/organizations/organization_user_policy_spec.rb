# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUserPolicy, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be_with_refind(:current_user) { create :user }

  subject(:policy) { described_class.new(current_user, organization_user) }

  shared_examples 'organization owner policy' do
    context 'when the current user is not an owner' do
      let_it_be_with_refind(:organization_user) do
        create(:organization_user, organization: organization, user: current_user)
      end

      it { is_expected.to be_disallowed(user_policy) }
    end

    context 'when the current user is an owner' do
      let_it_be_with_refind(:organization_user) do
        create(:organization_user, :owner, organization: organization, user: current_user)
      end

      context 'when the current user is the last owner' do
        it { is_expected.to be_disallowed(user_policy) }
      end

      context 'when the current user is not the last owner' do
        before do
          create(:organization_user, :owner, organization: organization)
        end

        it { is_expected.to be_allowed(user_policy) }
      end
    end

    context 'for admin user' do
      let_it_be_with_refind(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        context 'when the user is not an owner' do
          let_it_be_with_refind(:organization_user) { create(:organization_user, organization: organization) }

          it { is_expected.to be_allowed(user_policy) }
        end

        context 'when the user is an owner' do
          let_it_be_with_refind(:organization_user) do
            create(:organization_user, :owner, organization: organization)
          end

          context 'when the user is the last owner' do
            it { is_expected.to be_disallowed(user_policy) }
          end

          context 'when the user is not the last owner' do
            before do
              create(:organization_user, :owner, organization: organization)
            end

            it { is_expected.to be_allowed(user_policy) }
          end
        end
      end

      context 'when admin mode is disabled' do
        context 'when the user is not an owner' do
          let_it_be_with_refind(:organization_user) { create(:organization_user, organization: organization) }

          it { is_expected.to be_disallowed(user_policy) }
        end

        context 'when the user is an owner' do
          let_it_be_with_refind(:organization_user) do
            create(:organization_user, :owner, organization: organization)
          end

          context 'when the user is the last owner' do
            it { is_expected.to be_disallowed(user_policy) }
          end

          context 'when the user is not the last owner' do
            before do
              create(:organization_user, :owner, organization: organization)
            end

            it { is_expected.to be_disallowed(user_policy) }
          end
        end
      end
    end
  end

  context 'for update_organization_user policy' do
    let_it_be(:user_policy) { :update_organization_user }

    it_behaves_like 'organization owner policy'
  end

  context 'for remove_user policy' do
    let_it_be(:user_policy) { :remove_user }

    it_behaves_like 'organization owner policy'
  end

  context 'for delete_user policy' do
    let_it_be(:user_policy) { :delete_user }

    it_behaves_like 'organization owner policy'
  end
end
