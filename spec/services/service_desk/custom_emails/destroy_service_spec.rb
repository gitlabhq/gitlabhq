# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomEmails::DestroyService, feature_category: :service_desk do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }

    let(:user) { build_stubbed(:user) }
    let(:service) { described_class.new(project: project, current_user: user) }
    let(:error_user_not_authorized) { s_('ServiceDesk|User cannot manage project.') }
    let(:error_does_not_exist) { s_('ServiceDesk|Custom email does not exist') }
    let(:expected_error_message) { nil }
    let(:logger_params) { { category: 'custom_email' } }

    shared_examples 'a service that exits with error' do
      it 'exits early' do
        expect(Gitlab::AppLogger).to receive(:warn).with(logger_params.merge(
          error_message: expected_error_message
        )).once

        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq(expected_error_message)
      end
    end

    shared_examples 'a successful service that destroys all custom email records' do
      it 'ensures no custom email records exist' do
        expect(Gitlab::AppLogger).to receive(:info).with(logger_params).once

        project.reset

        response = service.execute

        expect(response).to be_success
        expect(project.service_desk_custom_email_verification).to be nil
        expect(project.service_desk_custom_email_credential).to be nil
        expect(project.service_desk_setting).to have_attributes(
          custom_email: nil,
          custom_email_enabled: false
        )
      end
    end

    context 'with illegitimate user' do
      let(:expected_error_message) { error_user_not_authorized }

      before do
        stub_member_access_level(project, developer: user)
      end

      it_behaves_like 'a service that exits with error'
    end

    context 'with legitimate user' do
      let(:expected_error_message) { error_does_not_exist }

      before do
        stub_member_access_level(project, maintainer: user)
      end

      it_behaves_like 'a service that exits with error'

      context 'when service desk setting exists' do
        let!(:settings) { create(:service_desk_setting, project: project) }

        it_behaves_like 'a successful service that destroys all custom email records'

        context 'when custom email is present' do
          let!(:settings) { create(:service_desk_setting, project: project, custom_email: 'user@example.com') }

          it_behaves_like 'a successful service that destroys all custom email records'

          context 'when credential exists' do
            let!(:credential) { create(:service_desk_custom_email_credential, project: project) }

            it_behaves_like 'a successful service that destroys all custom email records'

            context 'when verification exists' do
              let!(:verification) { create(:service_desk_custom_email_verification, project: project) }

              it_behaves_like 'a successful service that destroys all custom email records'
            end
          end
        end
      end
    end
  end
end
