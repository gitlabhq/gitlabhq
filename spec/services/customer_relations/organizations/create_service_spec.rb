# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Organizations::CreateService, feature_category: :service_desk do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:group) { create(:group) }
    let(:params) { attributes_for(:crm_organization, group: group) }

    subject(:response) { described_class.new(group: group, current_user: user, params: params).execute }

    it 'creates a crm_organization' do
      group.add_developer(user)

      expect(response).to be_success
    end

    it 'returns an error when user does not have permission' do
      group.add_reporter(user)

      expect(response).to be_error
      expect(response.message).to match_array(['You have insufficient permissions to create an organization for this group'])
    end

    it 'returns an error when the crm_organization is not persisted' do
      group.add_developer(user)
      params[:name] = nil

      expect(response).to be_error
      expect(response.message).to match_array(["Name can't be blank"])
    end
  end
end
