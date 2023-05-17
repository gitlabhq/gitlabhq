# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::RevokeService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:achievement) { create(:achievement, namespace: group) }
    let_it_be(:user_achievement) { create(:user_achievement, achievement: achievement) }

    let(:user_achievement_param) { user_achievement }

    subject(:response) { described_class.new(current_user, user_achievement_param).execute }

    before_all do
      group.add_developer(developer)
      group.add_maintainer(maintainer)
    end

    context 'when user does not have permission' do
      let(:current_user) { developer }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to revoke this achievement'])
      end
    end

    context 'when user has permission' do
      let(:current_user) { maintainer }

      it 'revokes an achievement' do
        expect(response).to be_success
      end

      context 'when the achievement has already been revoked' do
        let_it_be(:revoked_achievement) { create(:user_achievement, :revoked, achievement: achievement) }
        let(:user_achievement_param) { revoked_achievement }

        it 'returns the correct error' do
          expect(response).to be_error
          expect(response.message)
            .to contain_exactly('This achievement has already been revoked')
        end
      end

      context 'when the user achievement fails to save' do
        let(:user_achievement_param) { instance_double('Achievements::UserAchievement') }

        it 'returns the correct error' do
          allow(user_achievement_param).to receive(:save).and_return(false)
          allow(user_achievement_param).to receive(:achievement).and_return(achievement)
          allow(user_achievement_param).to receive(:revoked?).and_return(false)
          allow(user_achievement_param).to receive(:errors).and_return(nil)
          expect(user_achievement_param).to receive(:assign_attributes)

          expect(response).to be_error
          expect(response.message).to match_array(["Failed to revoke achievement"])
        end
      end
    end
  end
end
