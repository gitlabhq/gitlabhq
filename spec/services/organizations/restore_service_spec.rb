# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::RestoreService, feature_category: :organization do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:owner) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  let(:current_user) { admin }

  subject(:response) { described_class.new(organization, current_user: current_user).execute }

  before_all do
    create(:organization_user, :owner, organization: organization, user: owner)
  end

  describe '#execute' do
    context 'when the organization is soft-deleted' do
      before do
        organization.soft_delete(transition_user: admin)
        organization.reload
      end

      context 'when the user is not authorized' do
        let(:current_user) { create(:user) }

        it 'returns an error', :aggregate_failures do
          expect(response).to be_error
          expect(response.message).to eq('Insufficient permissions')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when the user is an organization owner but not an admin' do
        let(:current_user) { owner }

        it 'returns an error, because restore is admin-only', :aggregate_failures do
          expect(response).to be_error
          expect(response.message).to eq('Insufficient permissions')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when the user is a blocked admin', :enable_admin_mode do
        let(:current_user) { create(:admin, :blocked) }

        it 'returns an error, because the prevent rule blocks restore', :aggregate_failures do
          expect(response).to be_error
          expect(response.message).to eq('Insufficient permissions')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when the user is an admin', :enable_admin_mode do
        it 'transitions the organization to active state' do
          expect { response }.to change { organization.reload.state }.from('soft_deleted').to('active')
        end

        it 'clears the soft-deletion data', :aggregate_failures do
          response
          organization.reload

          expect(organization.soft_deleted_at).to be_nil
          expect(organization.state_metadata).not_to have_key('soft_deletion_scheduled_by_user_id')
        end

        it 'returns a success response with the organization', :aggregate_failures do
          expect(response).to be_success
          expect(response.payload[:organization]).to eq(organization)
        end

        it 'logs the event' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original
          expect(Gitlab::AppLogger).to receive(:info).with({
            'class' => 'Organizations::RestoreService',
            'message' => "Organization restored",
            Labkit::Fields::GL_USER_ID => admin.id,
            Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
            'organization_path' => organization.full_path
          })

          response
        end

        context 'when the state transition fails' do
          before do
            allow(organization).to receive_messages(restore: false, active?: false)
            allow(organization).to receive_message_chain(:errors, :full_messages).and_return(['state transition error'])
          end

          it 'returns an error', :aggregate_failures do
            expect(response).to be_error
            expect(response.message).to eq('state transition error')
            expect(response.payload[:organization]).to be_nil
          end
        end
      end
    end

    context 'when the organization is not soft-deleted', :enable_admin_mode do
      it 'returns an error', :aggregate_failures do
        expect(response).to be_error
        expect(response.message).to eq('Organization is not soft-deleted')
        expect(response.payload[:organization]).to be_nil
      end
    end
  end
end
