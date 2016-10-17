require 'spec_helper'

describe Users::ActivityService, services: true do
  let(:user) { create(:user) }
  subject(:service) { described_class.new(user, 'type') }

  describe '#execute' do
    context 'when last activity is nil' do
      it 'sets the last activity timestamp' do
        service.execute

        expect(user.last_activity_at).not_to be_nil
      end
    end

    context 'when activity_at is not nil' do
      it 'updates the activity multiple times' do
        activity = create(:user_activity, user: user)

        Timecop.travel(activity.last_activity_at + 1.minute) do
          expect { service.execute }.to change { user.reload.last_activity_at }
        end
      end
    end
  end
end
