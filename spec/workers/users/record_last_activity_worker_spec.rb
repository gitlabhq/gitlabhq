# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RecordLastActivityWorker, feature_category: :seat_cost_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:user_id) { user.id }
  let(:namespace_id) { group.id }

  let(:last_activity_event) do
    Users::ActivityEvent.new(data: { user_id: user_id, namespace_id: namespace_id })
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { last_activity_event }
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#handle_event' do
    let_it_be(:member) { create(:group_member, user: user, group: group, last_activity_on: 1.week.ago) }

    it 'updates the member timestamp' do
      expect do
        consume_event(subscriber: described_class, event: last_activity_event)
      end.to change { member.reload.last_activity_on }
    end

    shared_examples 'returns early' do
      it do
        expect(Users::ActivityService).not_to receive(:new)

        consume_event(subscriber: described_class, event: last_activity_event)
      end
    end

    context 'when the user is not found' do
      let(:user_id) { non_existing_record_id }

      it_behaves_like 'returns early'
    end

    context 'when the namespace is not found' do
      let(:namespace_id) { non_existing_record_id }

      it_behaves_like 'returns early'
    end
  end
end
