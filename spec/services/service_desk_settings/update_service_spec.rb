# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDeskSettings::UpdateService, :aggregate_failures, feature_category: :service_desk do
  describe '#execute' do
    let_it_be(:settings) do
      create(:service_desk_setting, outgoing_name: 'original name', custom_email: 'user@example.com')
    end

    let_it_be(:credential) do
      build(:service_desk_custom_email_credential, project: settings.project).save!(validate: false)
    end

    let_it_be(:verification) { create(:service_desk_custom_email_verification, :finished, project: settings.project) }
    let_it_be(:user) { create(:user) }

    context 'with valid params' do
      let(:params) do
        {
          outgoing_name: 'some name',
          project_key: 'foo',
          reopen_issue_on_external_participant_note: true,
          add_external_participants_from_cc: true,
          tickets_confidential_by_default: false
        }
      end

      it 'updates service desk settings' do
        response = described_class.new(settings.project, user, params).execute

        expect(response).to be_success
        expect(settings.reset).to have_attributes(
          outgoing_name: 'some name',
          project_key: 'foo',
          reopen_issue_on_external_participant_note: true,
          add_external_participants_from_cc: true,
          tickets_confidential_by_default: false
        )
      end

      context 'with custom email verification in finished state' do
        let(:params) { { custom_email_enabled: true } }

        before do
          allow(Gitlab::AppLogger).to receive(:info)
        end

        it 'allows to enable custom email' do
          settings.project.reset

          response = described_class.new(settings.project, user, params).execute

          expect(response).to be_success
          expect(settings.reset.custom_email_enabled).to be true
          expect(Gitlab::AppLogger).to have_received(:info).with({ category: 'custom_email' })
        end
      end

      context 'when issue_email_participants feature flag is disabled' do
        before do
          stub_feature_flags(issue_email_participants: false)
        end

        it 'updates service desk setting but not add_external_participants_from_cc value' do
          response = described_class.new(settings.project, user, params).execute

          expect(response).to be_success
          expect(settings.reset).to have_attributes(
            outgoing_name: 'some name',
            project_key: 'foo',
            add_external_participants_from_cc: false
          )
        end
      end
    end

    context 'when project_key is an empty string' do
      let(:params) { { project_key: '' } }

      it 'sets nil project_key' do
        response = described_class.new(settings.project, user, params).execute

        expect(response).to be_success
        expect(settings.reload.project_key).to be_nil
      end
    end

    context 'with invalid params' do
      let(:params) { { outgoing_name: 'x' * 256 } }

      it 'does not update service desk settings' do
        response = described_class.new(settings.project, user, params).execute

        expect(response).to be_error
        expect(response.message).to eq 'Outgoing name is too long (maximum is 255 characters)'
        expect(settings.reload.outgoing_name).to eq 'original name'
      end
    end
  end
end
