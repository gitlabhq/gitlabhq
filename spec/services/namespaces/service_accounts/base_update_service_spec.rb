# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::BaseUpdateService, feature_category: :user_management do
  let(:test_service_class) do
    Class.new(described_class) do
      private

      def extract_resource_id(params)
        params[:resource_id]
      end

      def resource
        @_resource ||= Group.find_by_id(@resource_id)
      end

      def user_provisioned_resource_id
        user.provisioned_by_group_id
      end

      def user_provisioned_resource
        user.provisioned_by_group
      end

      def invalid_resource_id_message
        s_('ServiceAccount|Resource ID provided does not match the service account\'s resource ID.')
      end

      def resource_not_found_message
        s_('ServiceAccount|Resource with the provided ID not found.')
      end
    end
  end

  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:group) { create(:group, organization: organization) }
  let_it_be(:other_group) { create(:group, organization: organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }

  let(:service_account_user) { create(:user, :service_account, provisioned_by_group: group) }
  let(:regular_user) { create(:user, provisioned_by_group: group) }

  let(:params) do
    {
      name: FFaker::Name.name,
      username: "service_account_#{SecureRandom.hex(8)}",
      email: FFaker::Internet.email,
      resource_id: group.id
    }
  end

  let(:current_user) { admin }

  subject(:service) { test_service_class.new(current_user, service_account_user, params) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  describe 'abstract method enforcement' do
    # Only override extract_resource_id to allow construction;
    # all other abstract methods remain from the base class.
    let(:constructable_base_class) do
      Class.new(described_class) do
        private

        def extract_resource_id(params)
          params[:resource_id]
        end
      end
    end

    let(:base_service) { constructable_base_class.new(current_user, service_account_user, params) }

    it 'raises Gitlab::AbstractMethodError for extract_resource_id' do
      expect { described_class.new(current_user, service_account_user, params) }
        .to raise_error(Gitlab::AbstractMethodError)
    end

    it 'raises Gitlab::AbstractMethodError for resource' do
      expect { base_service.send(:resource) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'raises Gitlab::AbstractMethodError for user_provisioned_resource_id' do
      expect { base_service.send(:user_provisioned_resource_id) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'raises Gitlab::AbstractMethodError for user_provisioned_resource' do
      expect { base_service.send(:user_provisioned_resource) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'raises Gitlab::AbstractMethodError for invalid_resource_id_message' do
      expect { base_service.send(:invalid_resource_id_message) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'raises Gitlab::AbstractMethodError for resource_not_found_message' do
      expect { base_service.send(:resource_not_found_message) }.to raise_error(Gitlab::AbstractMethodError)
    end
  end

  describe '#execute' do
    context 'when current user is an admin' do
      let(:current_user) { admin }

      context 'when admin mode is not enabled' do
        it_behaves_like 'service account update not authorized'
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it_behaves_like 'service account update success'
      end
    end

    context 'when current user is a group owner' do
      let(:current_user) { owner }

      it_behaves_like 'service account update success'
    end

    context 'when current user is a maintainer' do
      let(:current_user) { maintainer }

      it_behaves_like 'service account update not authorized'
    end

    context 'when resource is not found', :enable_admin_mode do
      let(:params) { super().merge(resource_id: non_existing_record_id) }

      it 'returns not found error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to eq(s_('ServiceAccount|Resource with the provided ID not found.'))
        expect(result.reason).to eq(:not_found)
      end
    end

    context 'when resource id does not match user provisioned resource id', :enable_admin_mode do
      let(:params) { super().merge(resource_id: other_group.id) }

      it 'returns invalid resource id error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to eq(
          s_('ServiceAccount|Resource ID provided does not match the service account\'s resource ID.')
        )
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when user is not a service account', :enable_admin_mode do
      let(:service_account_user) { regular_user }

      it 'returns error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to eq('User is not a service account')
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when username is already taken', :enable_admin_mode do
      let_it_be(:existing_user) { create(:user, username: 'existing_username') }
      let(:params) { super().merge(username: existing_user.username) }

      it 'returns error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to include('Username has already been taken')
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when provisioned resource is nil', :enable_admin_mode do
      let(:service_account_user) { create(:user, :service_account) }

      it 'returns error due to resource mismatch', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when user_provisioned_resource returns nil', :enable_admin_mode do
      it 'returns forbidden error', :aggregate_failures do
        allow(service).to receive(:user_provisioned_resource).and_return(nil)

        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.reason).to eq(:forbidden)
      end
    end

    context 'when updating name is disabled for regular users' do
      let(:current_user) { owner }

      before do
        stub_application_setting(updating_name_disabled_for_users: true)
      end

      it 'still updates the service account name via force_name_change', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:success)
        expect(result.message).to eq(_('Service account was successfully updated.'))
        expect(result.payload[:user]).to eq(service_account_user)
        expect(result.payload[:user].name).to eq(params[:name])
      end
    end

    context 'when user update fails' do
      let(:current_user) { owner }

      before do
        allow_next_instance_of(Users::UpdateService) do |update_service|
          # Users::UpdateService returns a hash, not a ServiceResponse
          allow(update_service).to receive(:execute).and_return({ status: :error, message: 'Update failed' })
        end
      end

      it 'returns an error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to eq('Update failed')
        expect(result.reason).to eq(:bad_request)
      end
    end

    context 'when email confirmation setting is set to hard', :enable_admin_mode do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
      end

      it 'updates the unconfirmed email instead of the email', :aggregate_failures do
        result = service.execute

        expect(result.payload[:user].unconfirmed_email).to eq(params[:email])
        expect(result.payload[:user].email).not_to eq(params[:email])
      end
    end
  end
end
