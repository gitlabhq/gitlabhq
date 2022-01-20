# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organizations::UpdateService do
  let_it_be(:user) { create(:user) }

  let(:organization) { create(:organization, name: 'Test', group: group) }

  subject(:update) { described_class.new(group: group, current_user: user, params: params).execute(organization) }

  describe '#execute' do
    context 'when the user has no permission' do
      let_it_be(:group) { create(:group, :crm_enabled) }

      let(:params) { { name: 'GitLab' } }

      it 'returns an error' do
        response = update

        expect(response).to be_error
        expect(response.message).to eq(['You have insufficient permissions to update an organization for this group'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group, :crm_enabled) }

      before_all do
        group.add_developer(user)
      end

      context 'when name is changed' do
        let(:params) { { name: 'GitLab' } }

        it 'updates the organization' do
          response = update

          expect(response).to be_success
          expect(response.payload.name).to eq('GitLab')
        end
      end

      context 'when the organization is invalid' do
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
