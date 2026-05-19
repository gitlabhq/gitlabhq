# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::GroupCreateService, feature_category: :user_management do
  shared_examples 'service account creation failure' do
    it 'produces an error', :aggregate_failures do
      expect(result.status).to eq(:error)
      expect(result.message).to eq(
        s_('ServiceAccount|User does not have permission to create a service account in this group.')
      )
    end
  end

  let_it_be(:organization) { create(:organization) }
  let_it_be(:group) { create(:group) }

  let(:namespace_id) { group.id }

  subject(:service) do
    described_class.new(current_user, { organization_id: organization.id, namespace_id: namespace_id })
  end

  context 'when current user is an admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'service account creation success' do
      let(:username_prefix) { "service_account_group_#{group.id}" }
    end

    it 'sets provisioned by group' do
      expect(result.payload[:user].provisioned_by_group_id).to eq(group.id)
    end

    context 'when the group is invalid' do
      let(:namespace_id) { non_existing_record_id }

      it_behaves_like 'service account creation failure'
    end

    context 'when namespace_id param is nil' do
      subject(:service) do
        described_class.new(current_user, { organization_id: organization.id, namespace_id: nil })
      end

      it 'fails to create service account due to nil namespace_id' do
        expect(result.status).to eq(:error)
        expect(result.message).to eq(
          s_('ServiceAccount|User does not have permission to create a service account in this group.')
        )
      end
    end
  end

  context 'when current user is not an admin' do
    context 'when not a group owner' do
      let_it_be(:current_user) { create(:user, maintainer_of: group) }

      it_behaves_like 'service account creation failure'
    end
  end

  describe 'with skip_owner_check params' do
    let_it_be(:current_user) { create(:user, maintainer_of: group) }

    context 'when skip_owner_check is true and composite_identity_enforced is true' do
      let(:params) do
        { organization_id: organization.id, namespace_id: namespace_id, skip_owner_check: true,
          composite_identity_enforced: true }
      end

      subject(:service) { described_class.new(current_user, params) }

      it 'creates a service account successfully with composite_identity_enforced', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:success)
        expect(result.payload[:user].confirmed?).to be(true)
        expect(result.payload[:user].composite_identity_enforced?).to be(true)
        expect(result.payload[:user].user_type).to eq('service_account')
        expect(result.payload[:user].external).to be(true)
      end

      it 'sets provisioned by group' do
        expect(result.payload[:user].provisioned_by_group_id).to eq(group.id)
      end
    end

    context 'when skip_owner_check is true but composite_identity_enforced is false' do
      let(:params) do
        { organization_id: organization.id, namespace_id: namespace_id, skip_owner_check: true,
          composite_identity_enforced: false }
      end

      subject(:service) { described_class.new(current_user, params) }

      it_behaves_like 'service account creation failure'
    end
  end

  def result
    service.execute
  end
end
