shared_examples_for 'throttled touch' do
  describe '#touch' do
    it 'updates the updated_at timestamp' do
      Timecop.freeze do
        subject.touch
        expect(subject.updated_at).to eq(Time.zone.now)
      end
    end

    it 'updates the object at most once per minute' do
      first_updated_at = Time.zone.now - (ThrottledTouch::TOUCH_INTERVAL * 2)
      second_updated_at = Time.zone.now - (ThrottledTouch::TOUCH_INTERVAL * 1.5)

      Timecop.freeze(first_updated_at) { subject.touch }
      Timecop.freeze(second_updated_at) { subject.touch }

      expect(subject.updated_at).to eq(first_updated_at)
    end
  end
end
