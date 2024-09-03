# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RegistrationsBuildService, feature_category: :system_access do
  describe '#execute' do
    let_it_be(:organization) { create(:organization) }
    let(:base_params) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }
    let(:skip_param) { {} }
    let(:params) { base_params.merge(skip_param).merge(organization_id: organization.id) }

    subject(:service) { described_class.new(nil, params) }

    before do
      stub_application_setting(signup_enabled?: true)
    end

    context 'with user_detail built' do
      it 'creates the user_detail record' do
        user = service.execute

        expect { user.save! }.to change { UserDetail.count }.by(1)
      end
    end

    context 'when automatic user confirmation is not enabled' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
      end

      context 'when skip_confirmation is true' do
        let(:skip_param) { { skip_confirmation: true } }

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when skip_confirmation is not set' do
        it 'does not confirm the user' do
          expect(service.execute).not_to be_confirmed
        end
      end

      context 'when skip_confirmation is false' do
        let(:skip_param) { { skip_confirmation: false } }

        it 'does not confirm the user' do
          expect(service.execute).not_to be_confirmed
        end
      end
    end

    context 'when automatic user confirmation is enabled' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'off')
      end

      context 'when skip_confirmation is true' do
        let(:skip_param) { { skip_confirmation: true } }

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when skip_confirmation is not set the application setting takes precedence' do
        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end

      context 'when skip_confirmation is false the application setting takes precedence' do
        let(:skip_param) { { skip_confirmation: false } }

        it 'confirms the user' do
          expect(service.execute).to be_confirmed
        end
      end
    end
  end
end
