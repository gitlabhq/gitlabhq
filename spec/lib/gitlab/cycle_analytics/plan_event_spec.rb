require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_event_spec'

describe Gitlab::CycleAnalytics::PlanEvent do
  it_behaves_like 'default query config' do
    it 'has the default order' do
      expect(event.order).to eq(event.start_time_attrs)
    end

    context 'no commits' do
      it 'does not blow up if there are no commits' do
        allow_any_instance_of(Gitlab::CycleAnalytics::EventsQuery).to receive(:execute).and_return([{}])

        expect { event.fetch }.not_to raise_error
      end
    end
  end
end
