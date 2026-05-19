# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::BaseCreateService, feature_category: :user_management do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:group) { create(:group) }

  let(:current_user) { admin }
  let(:params) { { organization_id: organization.id } }

  let(:test_service_class) do
    test_group = group
    Class.new(described_class) do
      define_method(:resource) { test_group }

      def resource_type
        'group'
      end

      def provisioning_params
        { group_id: resource.id, provisioned_by_group_id: resource.id }
      end
    end
  end

  subject(:service) { test_service_class.new(current_user, params) }

  describe 'abstract method enforcement' do
    let(:base_service) { described_class.new(current_user, params) }

    it 'raises Gitlab::AbstractMethodError for #resource' do
      expect { base_service.execute }.to raise_error(Gitlab::AbstractMethodError)
    end
  end

  describe '#execute', :enable_admin_mode do
    context 'when all conditions are met' do
      it 'creates service account successfully', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:success)
        expect(result.payload[:user].user_type).to eq('service_account')
        expect(result.payload[:user].provisioned_by_group_id).to eq(group.id)
      end

      it 'generates username with correct prefix' do
        result = service.execute

        expect(result.payload[:user].username).to start_with("service_account_group_#{group.id}")
      end
    end

    context 'when resource is nil' do
      before do
        allow_next_instance_of(test_service_class) do |svc|
          allow(svc).to receive(:resource).and_return(nil)
        end
      end

      it 'returns error' do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to include('does not have permission')
      end
    end

    context 'when user does not have permission' do
      let(:current_user) { create(:user) }

      it 'returns forbidden error', :aggregate_failures do
        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to include('does not have permission')
      end
    end

    context 'with uniquify_provided_username option' do
      let(:username_param) { 'my-username' }
      let(:params) { { organization_id: organization.id, username: username_param } }

      subject(:service) { test_service_class.new(current_user, params, uniquify_provided_username: true) }

      context 'when username is available' do
        it 'uses the provided username' do
          result = service.execute

          expect(result.payload[:user].username).to eq(username_param)
        end
      end

      context 'when username is taken by existing user' do
        before do
          create(:user, username: username_param)
        end

        it 'uniquifies the username', :aggregate_failures do
          result = service.execute
          username = result.payload[:user].username

          expect(username).to start_with(username_param)
          expect(username.length).to eq(username_param.length + 7)
        end
      end

      context 'when username conflicts with namespace path' do
        before do
          create(:group, path: username_param)
        end

        it 'uniquifies the username', :aggregate_failures do
          result = service.execute
          username = result.payload[:user].username

          expect(username).to start_with(username_param)
          expect(username.length).to eq(username_param.length + 7)
        end
      end
    end
  end

  describe '#skip_owner_check?' do
    it 'returns false by default' do
      expect(service.send(:skip_owner_check?)).to be false
    end
  end
end
