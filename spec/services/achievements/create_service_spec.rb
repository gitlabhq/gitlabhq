# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::CreateService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:params) { attributes_for(:achievement, namespace: group) }

    subject(:response) { described_class.new(namespace: group, current_user: user, params: params).execute }

    context 'when user does not have permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_developer(user)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to create achievements for this namespace'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_maintainer(user)
      end

      it 'creates an achievement' do
        expect(response).to be_success
      end

      it 'returns an error when the achievement is not persisted' do
        params[:name] = nil

        expect(response).to be_error
        expect(response.message).to match_array(["Name can't be blank"])
      end
    end
  end
end
