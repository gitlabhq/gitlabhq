# frozen_string_literal: true

RSpec.shared_examples 'a time trackable' do
  describe '#reload' do
    it 'clears memoized total_time_spent' do
      expect(trackable).to receive(:clear_memoization).with(:total_time_spent)

      trackable.reload
    end
  end

  describe '#reset' do
    it 'clears memoized total_time_spent' do
      expect(trackable).to receive(:clear_memoization).with(:total_time_spent)

      trackable.reset
    end
  end

  describe '#total_time_spent' do
    let(:user) { create(:user) }

    before do
      trackable.project.add_developer(user)
    end

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

    context 'when trackable is saved' do
      it 'gets cleared' do
        allow(trackable).to receive(:clear_memoization)

        trackable.save!

        expect(trackable).to have_received(:clear_memoization).with(:total_time_spent)
      end
    end
  end
end
