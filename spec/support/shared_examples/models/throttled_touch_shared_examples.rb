# frozen_string_literal: true

RSpec.shared_examples 'throttled touch' do
  describe '#touch' do
    it 'updates the updated_at timestamp' do
      freeze_time do
        subject.touch
        expect(subject.updated_at).to be_like_time(Time.zone.now)
      end
    end

    it 'updates the object at most once per minute' do
      first_updated_at = Time.zone.now - (ThrottledTouch::TOUCH_INTERVAL * 2)
      second_updated_at = Time.zone.now - (ThrottledTouch::TOUCH_INTERVAL * 1.5)

      travel_to(first_updated_at) { subject.touch }
      travel_to(second_updated_at) { subject.reload.touch }

      expect(subject.updated_at).to be_like_time(first_updated_at)
    end
  end
end
