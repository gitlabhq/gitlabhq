require 'spec_helper'

describe Users::ActivityService do
  include UserActivitiesHelpers

  let(:user) { create(:user) }

  subject(:service) { described_class.new(user, 'type') }

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when last activity is nil' do
      before do
        service.execute
      end

      it 'sets the last activity timestamp for the user' do
        expect(last_hour_user_ids).to eq([user.id])
      end

      it 'updates the same user' do
        service.execute

        expect(last_hour_user_ids).to eq([user.id])
      end

      it 'updates the timestamp of an existing user' do
        Timecop.freeze(Date.tomorrow) do
          expect { service.execute }.to change { user_activity(user) }.to(Time.now.to_i.to_s)
        end
      end

      describe 'other user' do
        it 'updates other user' do
          other_user = create(:user)
          described_class.new(other_user, 'type').execute

          expect(last_hour_user_ids).to match_array([user.id, other_user.id])
        end
      end
    end

    context 'when in GitLab read-only instance' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it 'does not update last_activity_at' do
        service.execute

        expect(last_hour_user_ids).to eq([])
      end
    end
  end

  def last_hour_user_ids
    Gitlab::UserActivities.new
      .select { |k, v| v >= 1.hour.ago.to_i.to_s }
      .map { |k, _| k.to_i }
  end
end
