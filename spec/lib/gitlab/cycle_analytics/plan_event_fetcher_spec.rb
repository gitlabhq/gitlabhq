# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::PlanEventFetcher do
  let(:stage_name) { :plan }

  it_behaves_like 'default query config' do
    context 'no commits' do
      it 'does not blow up if there are no commits' do
        allow(event).to receive(:event_result).and_return([{}])

        expect { event.fetch }.not_to raise_error
      end
    end
  end
end
