# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ServiceAccounts::CreateService, feature_category: :user_management do
  let_it_be(:organization) { create(:organization) }
  let(:params) { { organization_id: organization.id } }

  shared_examples 'service account creation failure' do
    it 'produces an error', :aggregate_failures do
      result = described_class.new(current_user).execute

      expect(result.status).to eq(:error)
      expect(result.message).to eq(s_('ServiceAccount|User does not have permission to create a service account.'))
    end
  end

  subject(:service) { described_class.new(current_user, params) }

  context 'when current user is an admin', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'service account creation success' do
      let(:username_prefix) { 'service_account' }
    end

    it_behaves_like 'service account creation with customized params'

    it 'correctly returns active model errors' do
      service.execute

      result = service.execute

      expect(result.status).to eq(:error)
      expect(result.message).to eq('Email has already been taken and Username has already been taken')
    end

    context 'when username is blank' do
      let(:params) { { username: '   ', organization_id: organization.id } }

      it 'uses auto-generated username' do
        user = service.execute.payload[:user]
        expect(user.username).to start_with('service_account')
      end
    end

    context 'when email is blank' do
      let(:params) { { email: '', organization_id: organization.id } }

      it 'uses auto-generated email' do
        user = service.execute.payload[:user]
        expect(user.email).to start_with('service_account')
      end
    end

    context 'when name is blank' do
      let(:params) { { name: '   ', organization_id: organization.id } }

      it 'uses default name' do
        user = service.execute.payload[:user]
        expect(user.name).to eq('Service account user')
      end
    end

    describe '#creation_allowed?' do
      it 'delegates to Authn::ServiceAccounts.creation_allowed_for_sm?' do
        expect(::Authn::ServiceAccounts)
          .to receive(:creation_allowed_for_sm?).and_call_original

        service.execute
      end

      it 'allows creation when under the free-tier seat limit' do
        result = service.execute

        expect(result.status).to eq(:success)
      end

      context 'when free tier limit is reached' do
        before do
          stub_const("Authn::ServiceAccounts::LIMIT_FOR_FREE", 0)
        end

        it 'returns a seat limit error' do
          result = service.execute

          expect(result.status).to eq(:error)
          expect(result.message).to eq(s_(
          'ServiceAccount|This namespace either does not have an active subscription that can create service ' \
            'accounts, or the subscription has reached its service account creation limit.'))
        end
      end
    end
  end

  context 'when the current user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'service account creation failure'
  end
end
