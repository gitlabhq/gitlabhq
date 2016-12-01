require 'spec_helper'

describe Users::ActivityService, services: true do
  include UserActivitiesHelpers

  let(:user) { create(:user) }

  subject(:service) { described_class.new(user, 'type') }

  describe '#execute', :redis do
    context 'when last activity is nil' do
      before do
        service.execute
      end

      it 'sets the last activity timestamp for the user' do
        expect(last_hour_members).to eq([user.username])
      end

      it 'updates the same user' do
        service.execute

        expect(last_hour_members).to eq([user.username])
      end

      it 'updates the timestamp of an existing user' do
        Timecop.freeze(Date.tomorrow) do
          expect { service.execute }.to change { user_score }.to(Time.now.to_i)
        end
      end

      describe 'other user' do
        it 'updates other user' do
          other_user = create(:user)
          described_class.new(other_user, 'type').execute

          expect(last_hour_members).to match_array([user.username, other_user.username])
        end
      end
    end

    context 'when in Geo secondary node' do
      before { allow(Gitlab::Geo).to receive(:secondary?).and_return(true) }

      it 'does not update last_activity_at' do
        service.execute

        expect(last_hour_members).to eq([])
      end
    end
  end
end
