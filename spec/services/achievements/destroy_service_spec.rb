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

    context 'when there is no user' do
      let(:current_user) { nil }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to delete this achievement'])
      end
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

      it 'deletes the awarded and revoked user achievements of the achievement only' do
        awarded = create(:user_achievement, achievement: achievement)
        revoked = create(:user_achievement, :revoked, achievement: achievement)
        other_award = create(:user_achievement, achievement: create(:achievement, namespace: group))

        expect(response).to be_success
        expect(Achievements::UserAchievement.id_in([awarded.id, revoked.id])).to be_empty
        expect(Achievements::UserAchievement.exists?(other_award.id)).to be(true)
      end

      context 'when the achievement has an avatar' do
        let(:achievement) { create(:achievement, :with_avatar, namespace: group) }

        it 'removes the avatar upload and its stored file' do
          upload = Upload.find_by!(model: achievement, uploader: AvatarUploader.name)
          avatar_path = achievement.avatar.path

          expect(File).to exist(avatar_path)

          expect(response).to be_success
          expect(Upload.exists?(upload.id)).to be(false)
          expect(File).not_to exist(avatar_path)
        end
      end

      context 'when the achievement is not destroyed' do
        it 'returns an error and keeps the achievement' do
          allow(achievement).to receive(:destroy).and_return(false)

          expect(response).to be_error
          expect(response.message).to match_array(['Failed to delete achievement'])
          expect(Achievements::Achievement.exists?(achievement.id)).to be(true)
        end

        it 'returns the errors the achievement reports' do
          allow(achievement).to receive(:destroy) do
            achievement.errors.add(:base, 'Achievement cannot be deleted')
            false
          end

          expect(response).to be_error
          expect(response.message).to match_array(['Achievement cannot be deleted'])
        end
      end
    end
  end
end
