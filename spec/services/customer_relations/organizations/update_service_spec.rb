# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organizations::UpdateService, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }

  let(:crm_organization) { create(:crm_organization, name: 'Test', group: group, state: 'active') }

  subject(:update) { described_class.new(group: group, current_user: user, params: params).execute(crm_organization) }

  describe '#execute' do
    context 'when the user has no permission' do
      let_it_be(:group) { create(:group) }

      let(:params) { { name: 'GitLab' } }

      it 'returns an error' do
        response = update

        expect(response).to be_error
        expect(response.message).to eq(['You have insufficient permissions to update an organization for this group'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_developer(user)
      end

      context 'when name is changed' do
        let(:params) { { name: 'GitLab' } }

        it 'updates the crm_organization' do
          response = update

          expect(response).to be_success
          expect(response.payload.name).to eq('GitLab')
        end
      end

      context 'when activating' do
        let(:crm_organization) { create(:crm_organization, state: 'inactive') }
        let(:params) { { active: true } }

        it 'updates the contact' do
          response = update

          expect(response).to be_success
          expect(response.payload.active?).to be_truthy
        end
      end

      context 'when deactivating' do
        let(:params) { { active: false } }

        it 'updates the crm_organization' do
          response = update

          expect(response).to be_success
          expect(response.payload.active?).to be_falsy
        end
      end

      context 'when the crm_organization is invalid' do
        let(:params) { { name: nil } }

        it 'returns an error' do
          response = update

          expect(response).to be_error
          expect(response.message).to eq(["Name can't be blank"])
        end
      end
    end
  end
end
