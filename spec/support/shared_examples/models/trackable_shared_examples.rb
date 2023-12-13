# frozen_string_literal: true

RSpec.shared_examples 'a time trackable' do
  describe '#total_time_spent' do
    context 'when total time spent exceeds the allowed limit' do
      let(:time_spent) { Timelog::MAX_TOTAL_TIME_SPENT + 1.second }

      it 'returns the maximum allowed total time spent' do
        timelog.update_column(:time_spent, time_spent.to_i)

        expect(trackable.total_time_spent).to eq(Timelog::MAX_TOTAL_TIME_SPENT)
      end

      context 'when total time spent is below 0' do
        let(:time_spent) { -Timelog::MAX_TOTAL_TIME_SPENT - 1.second }

        it 'returns the minimum allowed total time spent' do
          timelog.update_column(:time_spent, time_spent.to_i)

          expect(trackable.total_time_spent).to eq(-Timelog::MAX_TOTAL_TIME_SPENT)
        end
      end
    end
  end
end
