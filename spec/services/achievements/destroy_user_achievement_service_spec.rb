# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::DestroyUserAchievementService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:group) { create(:group) }

    let_it_be(:achievement) { create(:achievement, namespace: group) }
    let_it_be(:user_achievement) { create(:user_achievement, achievement: achievement) }

    subject(:response) { described_class.new(current_user, user_achievement).execute }

    before_all do
      group.add_maintainer(maintainer)
      group.add_owner(owner)
    end

    context 'when user does not have permission' do
      let(:current_user) { maintainer }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to delete this user achievement'])
      end
    end

    context 'when user has permission' do
      let(:current_user) { owner }

      it 'deletes the achievement' do
        expect(response).to be_success
        expect(Achievements::UserAchievement.find_by(id: user_achievement.id)).to be_nil
      end
    end
  end
end
