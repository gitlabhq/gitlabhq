# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ActivityService, :clean_gitlab_redis_shared_state, feature_category: :seat_cost_management do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  let(:lease_key) { "members_activity_event:#{namespace.id}:#{user.id}" }
  let(:instance) { described_class.new(user, namespace) }

  describe '#execute' do
    subject(:execute) { instance.execute }

    shared_examples 'does not update last_activity_on' do
      it do
        expect_next_found_instance_of(Member) do |member|
          expect(member).not_to receive(:touch).with(:last_activity_on)
        end

        expect(execute).to be_success
      end
    end

    shared_examples 'updates last_activity_on' do
      it 'updates the members last activity timestamp' do
        expect(execute).to be_success

        expect(member.reload.last_activity_on).to eq Date.today
      end

      it 'tries to obtain a lease', :freeze_time do
        ttl = (Time.current.end_of_day - Time.current).to_i
        expect_to_obtain_exclusive_lease(lease_key, timeout: ttl)

        expect(execute).to be_success
      end

      context 'when a lease cannot be obtained' do
        it 'returns success' do
          stub_exclusive_lease_taken(lease_key)

          expect(execute).to be_success
        end
      end
    end

    shared_examples 'tracking a group member' do
      context 'when last activity was before today' do
        let_it_be(:member) do
          create(:group_member, :developer, user: user, group: namespace, last_activity_on: Date.yesterday)
        end

        it_behaves_like 'updates last_activity_on'
      end

      context 'when last activity was today' do
        let_it_be(:member) do
          create(:group_member, :developer, user: user, group: namespace, last_activity_on: Date.today)
        end

        it_behaves_like 'does not update last_activity_on'
      end
    end

    shared_examples 'tracking a project member' do
      context 'when last activity was before today' do
        let_it_be(:member) do
          create(:project_member, :developer, user: user, project: project, last_activity_on: Date.yesterday)
        end

        it_behaves_like 'updates last_activity_on'
      end

      context 'when last activity was today' do
        let_it_be(:member) do
          create(:project_member, :developer, user: user, project: project, last_activity_on: Date.today)
        end

        it_behaves_like 'does not update last_activity_on'
      end
    end

    shared_examples 'returns an error' do
      it do
        response = execute

        expect(response).to be_error
        expect(response.message).to eq('Invalid params')
      end
    end

    context 'with a namespace' do
      it_behaves_like 'tracking a group member'
      it_behaves_like 'tracking a project member'
    end

    context 'with no namespace' do
      let(:namespace) { nil }

      it_behaves_like 'returns an error'
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'returns an error'
    end

    context 'with no member for namespace and user' do
      it 'returns does not raise an error' do
        response = execute

        expect(response).to be_success
      end

      it 'releases the lease' do
        expect_to_obtain_exclusive_lease(lease_key, 'uuid')
        expect_to_cancel_exclusive_lease(lease_key, 'uuid')

        execute
      end
    end
  end
end
