# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ActivityService, feature_category: :user_profile do
  include ExclusiveLeaseHelpers

  let(:user) { create(:user, last_activity_on: last_activity_on) }

  subject { described_class.new(author: user) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    shared_examples 'does not update last_activity_on' do
      it 'does not update user attribute' do
        expect { subject.execute }.not_to change(user, :last_activity_on)
      end

      it 'does not track Snowplow event' do
        subject.execute

        expect_no_snowplow_event
      end
    end

    context 'when last activity is nil' do
      let(:last_activity_on) { nil }

      it 'updates last_activity_on for the user' do
        expect { subject.execute }
          .to change(user, :last_activity_on).from(last_activity_on).to(Date.today)
      end
    end

    context 'when last activity is in the past' do
      let(:last_activity_on) { Date.today - 1.week }

      it 'updates last_activity_on for the user' do
        expect { subject.execute }
          .to change(user, :last_activity_on)
                .from(last_activity_on)
                .to(Date.today)
      end

      it 'tries to obtain ExclusiveLease' do
        expect(Gitlab::ExclusiveLease).to receive(:new).with("activity_service:#{user.id}", anything).and_call_original

        subject.execute
      end

      it 'tracks RedisHLL event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with('unique_active_user', values: user.id)

        subject.execute
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject(:record_activity) { described_class.new(author: user, namespace: namespace, project: project).execute }

        let(:category) { described_class.name }
        let(:action) { 'perform_action' }
        let(:label) { 'redis_hll_counters.manage.unique_active_users_monthly' }
        let(:namespace) { build(:group) }
        let(:project) { build(:project) }
        let(:context) do
          payload = Gitlab::Tracking::ServicePingContext.new(
            data_source: :redis_hll,
            event: 'unique_active_user'
          ).to_context

          [Gitlab::Json.dump(payload)]
        end
      end
    end

    context 'when a bad object is passed' do
      let(:fake_object) { double(username: 'hello') }

      it 'does not record activity' do
        service = described_class.new(author: fake_object)

        expect(service).not_to receive(:record_activity)

        service.execute
      end
    end

    context 'when last activity is today' do
      let(:last_activity_on) { Date.today }

      it_behaves_like 'does not update last_activity_on'

      it 'does not try to obtain ExclusiveLease' do
        expect(Gitlab::ExclusiveLease).not_to receive(:new).with("activity_service:#{user.id}", anything)

        subject.execute
      end
    end

    context 'when in GitLab read-only instance' do
      let(:last_activity_on) { nil }

      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it_behaves_like 'does not update last_activity_on'
    end

    context 'when a lease could not be obtained' do
      let(:last_activity_on) { nil }

      before do
        stub_exclusive_lease_taken("activity_service:#{user.id}", timeout: 1.minute.to_i)
      end

      it_behaves_like 'does not update last_activity_on'
    end
  end

  context 'with DB Load Balancing' do
    let(:user) { create(:user, last_activity_on: last_activity_on) }

    context 'when last activity is in the past' do
      let(:user) { create(:user, last_activity_on: Date.today - 1.week) }
      let(:lb) { User.load_balancer }

      context 'database load balancing is configured' do
        before do
          ::Gitlab::Database::LoadBalancing::SessionMap.clear_session
        end

        let(:service) do
          service = described_class.new(author: user)

          ::Gitlab::Database::LoadBalancing::SessionMap.clear_session

          service
        end

        it 'does not stick to primary' do
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).not_to be_performed_write

          service.execute

          expect(user.last_activity_on).to eq(Date.today)
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).to be_performed_write
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(lb)).not_to be_using_primary
        end
      end

      context 'database load balancing is not configured' do
        let(:service) { described_class.new(author: user) }

        it 'updates user without error' do
          service.execute

          expect(user.last_activity_on).to eq(Date.today)
        end
      end
    end
  end
end
