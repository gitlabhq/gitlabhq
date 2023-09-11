# frozen_string_literal: true

RSpec.shared_examples 'namespace visits model' do
  it { is_expected.to validate_presence_of(:entity_id) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:visited_at) }

  describe '#visited_around?' do
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
end
