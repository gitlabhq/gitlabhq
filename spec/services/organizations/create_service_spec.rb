# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::CreateService, feature_category: :cell do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:current_user) { user }
    let(:params) { attributes_for(:organization) }

    subject(:response) { described_class.new(current_user: current_user, params: params).execute }

    context 'when user does not have permission' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(response).to be_error

        expect(response.message).to match_array(
          ['You have insufficient permissions to create organizations'])
      end
    end

    context 'when user has permission' do
      it 'creates an organization' do
        expect { response }.to change { Organizations::Organization.count }

        expect(response).to be_success
      end

      it 'returns an error when the organization is not persisted' do
        params[:name] = nil

        expect(response).to be_error
        expect(response.message).to match_array(["Name can't be blank"])
      end
    end
  end
end
