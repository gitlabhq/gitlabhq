# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contacts::CreateService, feature_category: :service_desk do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:not_found_or_does_not_belong) { 'The specified organization was not found or does not belong to this group' }

    let(:params) { attributes_for(:contact, group: group) }

    subject(:response) { described_class.new(group: group, current_user: user, params: params).execute }

    context 'when user does not have permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_reporter(user)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(['You have insufficient permissions to manage contacts for this group'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_developer(user)
      end

      it 'creates a contact' do
        expect(response).to be_success
      end

      it 'returns an error when the contact is not persisted' do
        params[:last_name] = nil

        expect(response).to be_error
        expect(response.message).to match_array(["Last name can't be blank"])
      end

      it 'returns an error when the organization_id is invalid' do
        params[:organization_id] = non_existing_record_id

        expect(response).to be_error
        expect(response.message).to match_array([not_found_or_does_not_belong])
      end

      it 'returns an error when the organization belongs to a different group' do
        crm_organization = create(:crm_organization)
        params[:organization_id] = crm_organization.id

        expect(response).to be_error
        expect(response.message).to match_array([not_found_or_does_not_belong])
      end
    end
  end
end
