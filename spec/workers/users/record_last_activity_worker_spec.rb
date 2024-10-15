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

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#handle_event' do
    it 'handles the event successfully' do
      expect(consume_event(subscriber: described_class, event: last_activity_event))
        .to match_array([{ "namespace_id" => namespace_id, "user_id" => user_id }])
    end
  end
end
