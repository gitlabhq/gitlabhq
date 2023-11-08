# frozen_string_literal: true

RSpec.shared_examples 'namespace visits model' do
  it { is_expected.to validate_presence_of(:entity_id) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:visited_at) }

  describe '#visited_around?' do
    before do
      described_class.create!(entity_id: entity.id, user_id: user.id, visited_at: base_time)
    end

    context 'when the checked time matches a recent visit' do
      [-15.minutes, 15.minutes].each do |time_diff|
        it 'returns true' do
          expect(described_class.visited_around?(entity_id: entity.id, user_id: user.id,
            time: base_time + time_diff)).to be(true)
        end
      end
    end

    context 'when the checked time does not match a recent visit' do
      [-16.minutes, 16.minutes].each do |time_diff|
        it 'returns false' do
          expect(described_class.visited_around?(entity_id: entity.id, user_id: user.id,
            time: base_time + time_diff)).to be(false)
        end
      end
    end
  end

  describe '#frecent_visits_scores' do
    def frecent_visits_scores_to_array(visits)
      visits.map { |visit| [visit["entity_id"], visit["score"]] }
    end

    context 'when there is lots of data' do
      before do
        create_visit_records
      end

      it 'returns the frecent items, sorted by their frecency score' do
        expect(frecent_visits_scores_to_array(described_class.frecent_visits_scores(user_id: user.id,
          limit: 10))).to eq([[2, 31], [1, 30], [3, 28], [6, 6], [7, 6], [8, 6], [4, 6], [5, 6]])
      end

      it 'limits the amount of returned entries' do
        expect(frecent_visits_scores_to_array(described_class.frecent_visits_scores(user_id: user.id,
          limit: 2))).to eq([
            [2, 31], [1, 30]
          ])
      end
    end

    context 'when there is few data' do
      before do
        [
          # Multiplier: 4
          [1, Time.current],

          # Multiplier: 3
          [2, 2.weeks.ago],
          [3, 2.weeks.ago],

          # Multiplier: 2
          [1, 3.weeks.ago],
          [1, 3.weeks.ago],

          # Multiplier: 1
          [2, 5.weeks.ago]
        ].each do |id, datetime|
          described_class.create!(entity_id: id, user_id: user.id, visited_at: datetime)
        end
      end

      it 'returns the frecent items, sorted by their frecency score' do
        expect(frecent_visits_scores_to_array(described_class.frecent_visits_scores(user_id: user.id,
          limit: 5))).to eq([
            [1, 8], # Entity 1 gets a score of (1 * 4) + (2 * 2) = 8
            [2, 4], # Entity 2 gets a score of (1 * 3) + (1 * 1) = 4
            [3, 3]  # Entity 3 gets a score of 1 * 3 = 3
          ])
      end
    end
  end

  private

  # rubocop: disable Metrics/AbcSize -- Despite being long, this method is quite straightforward. Splitting it in smaller chunks would likely harm readability more than anything.
  def create_visit_records
    [
      [1, Time.current],

      [2, 1.week.ago],
      [2, 1.week.ago],

      [2, 2.weeks.ago],
      [3, 2.weeks.ago],
      [3, 2.weeks.ago],
      [4, 2.weeks.ago],
      [5, 2.weeks.ago],
      [6, 2.weeks.ago],
      [7, 2.weeks.ago],
      [8, 2.weeks.ago],

      [1, 3.weeks.ago],
      [1, 3.weeks.ago],
      [3, 3.weeks.ago],
      [3, 3.weeks.ago],

      [1, 4.weeks.ago],
      [2, 4.weeks.ago],
      [2, 4.weeks.ago],

      [3, 7.weeks.ago],
      [3, 7.weeks.ago],

      [1, 8.weeks.ago],
      [1, 8.weeks.ago],
      [1, 8.weeks.ago],
      [1, 8.weeks.ago],

      [2, 9.weeks.ago],
      [2, 9.weeks.ago],
      [2, 9.weeks.ago]
    ].each do |id, datetime|
      described_class.create!(entity_id: id, user_id: user.id, visited_at: datetime)
    end
  end
  # rubocop: enable Metrics/AbcSize
end
