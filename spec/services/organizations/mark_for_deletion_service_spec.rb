# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::MarkForDeletionService, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:organization) { create(:organization) }

  subject(:response) { described_class.new(organization, current_user: user).execute }

  describe '#execute' do
    context 'when user does not have permission' do
      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to eq('Insufficient permissions')
        expect(response.payload[:organization]).to be_nil
      end
    end

    context 'when user has permission' do
      before_all do
        create(:organization_user, :owner, organization: organization, user: user)
      end

      context 'when organization is the default organization' do
        let(:organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the delete_organization policy disallows deletion of the default organization

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Insufficient permissions')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when organization is not empty' do
        before do
          create(:group, organization: organization)
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Organization must be empty before it can be deleted')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when organization is already scheduled for deletion' do
        before do
          described_class.new(organization, current_user: user).execute
          organization.reload
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Organization has already been marked for deletion')
          expect(response.payload[:organization]).to be_nil
        end
      end

      context 'when organization is empty and not default' do
        it 'transitions the organization to deletion_scheduled state' do
          expect { response }.to change { organization.reload.state }.from('active').to('deletion_scheduled')
        end

        it 'returns a success response with the organization' do
          expect(response).to be_success
          expect(response.payload[:organization]).to eq(organization)
        end

        it 'logs the event' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original
          expect(Gitlab::AppLogger).to receive(:info).with({
            'class' => 'Organizations::MarkForDeletionService',
            'message' => "Organization marked for deletion",
            Labkit::Fields::GL_USER_ID => user.id,
            Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
            'organization_path' => organization.full_path
          })

          response
        end
      end

      context 'when the state transition fails' do
        before do
          allow(organization).to receive_messages(schedule_deletion: false, deletion_scheduled?: false)
          allow(organization).to receive_message_chain(:errors, :full_messages).and_return(['state transition error'])
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('state transition error')
          expect(response.payload[:organization]).to be_nil
        end
      end
    end
  end
end
