# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FreezePeriodPresenter, feature_category: :release_orchestration do
  let_it_be(:project) { build_stubbed(:project) }

  let(:presenter) { described_class.new(freeze_period) }

  describe '#start_time' do
    let(:freeze_period) { build_stubbed(:ci_freeze_period, project: project) }

    context 'when active' do
      # Default freeze period factory is on a weekend, so let's travel in time to a Saturday!
      let(:time) { Time.utc(2022, 12, 3, 6) }
      let(:previous_start) { Time.utc(2022, 12, 2, 23) }

      it 'returns the previous time of the freeze period start' do
        travel_to(time) do
          expect(presenter.start_time).to eq(previous_start)
        end
      end
    end

    context 'when inactive' do
      # Default freeze period factory is on a weekend, so we travel back a couple of days earlier.
      let(:time) { Time.utc(2022, 11, 30, 6) }
      let(:next_start) { Time.utc(2022, 12, 2, 23) }

      it 'returns the next time of the freeze period start' do
        travel_to(time) do
          expect(presenter.start_time).to eq(next_start)
        end
      end
    end
  end
end
