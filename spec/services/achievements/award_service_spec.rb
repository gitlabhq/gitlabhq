# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Achievements::AwardService, feature_category: :user_profile do
  describe '#execute' do
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:achievement) { create(:achievement, namespace: group) }
    let_it_be(:recipient) { create(:user) }

    let(:achievement_id) { achievement.id }
    let(:recipient_id) { recipient.id }

    subject(:response) { described_class.new(current_user, achievement_id, recipient_id).execute }

    before_all do
      group.add_developer(developer)
      group.add_maintainer(maintainer)
    end

    context 'when user does not have permission' do
      let(:current_user) { developer }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to match_array(
          ['You have insufficient permissions to award this achievement'])
      end
    end

    context 'when user has permission' do
      let(:current_user) { maintainer }
      let(:notification_service) { instance_double(NotificationService) }
      let(:mail_message) { instance_double(ActionMailer::MessageDelivery) }

      it 'creates an achievement and sends an e-mail' do
        allow(NotificationService).to receive(:new).and_return(notification_service)
        expect(notification_service).to receive(:new_achievement_email).with(recipient, achievement)
          .and_return(mail_message)
        expect(mail_message).to receive(:deliver_later)

        expect(response).to be_success
      end

      context 'when the achievement is not persisted' do
        let(:user_achievement) { instance_double('Achievements::UserAchievement') }

        it 'returns the correct error' do
          allow(user_achievement).to receive(:persisted?).and_return(false)
          allow(user_achievement).to receive(:errors).and_return(nil)
          allow(Achievements::UserAchievement).to receive(:create).and_return(user_achievement)

          expect(response).to be_error
          expect(response.message).to match_array(["Failed to award achievement"])
        end
      end

      context 'when the achievement does not exist' do
        let(:achievement_id) { non_existing_record_id }

        it 'returns the correct error' do
          expect(response).to be_error
          expect(response.message)
            .to contain_exactly("Couldn't find Achievements::Achievement with 'id'=#{non_existing_record_id}")
        end
      end

      context 'when the recipient does not exist' do
        let(:recipient_id) { non_existing_record_id }

        it 'returns the correct error' do
          expect(response).to be_error
          expect(response.message).to contain_exactly("Couldn't find User with 'id'=#{non_existing_record_id}")
        end
      end
    end
  end
end
