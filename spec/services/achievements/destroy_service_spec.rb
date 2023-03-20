# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::DestroyService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:achievement) { create(:achievement, namespace: group) }

    subject(:response) { described_class.new(current_user, achievement).execute }

    before_all do
      group.add_developer(developer)
      group.add_maintainer(maintainer)
    end

    context 'when user does not have permission' do
      let(:current_user) { developer }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to delete this achievement'])
      end
    end

    context 'when user has permission' do
      let(:current_user) { maintainer }

      it 'deletes the achievement' do
        expect(response).to be_success
        expect(Achievements::Achievement.find_by(id: achievement.id)).to be_nil
      end
    end
  end
end
