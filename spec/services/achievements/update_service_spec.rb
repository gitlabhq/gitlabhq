# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::UpdateService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:params) { attributes_for(:achievement, namespace: group) }

    subject(:response) { described_class.new(user, group, params).execute }

    context 'when user does not have permission' do
      let_it_be(:group) { create(:group) }
      let_it_be(:achievement) { create(:achievement, namespace: group) }

      before_all do
        group.add_developer(user)
      end

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permission to update this achievement'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group) }
      let_it_be(:achievement) { create(:achievement, namespace: group) }

      before_all do
        group.add_maintainer(user)
      end

      it 'updates an achievement' do
        expect(response).to be_success
      end

      it 'returns an error when the achievement cannot be updated' do
        params[:name] = nil

        expect(response).to be_error
        expect(response.message).to include("Name can't be blank")
      end
    end
  end
end
