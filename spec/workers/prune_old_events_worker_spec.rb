require 'spec_helper'

describe PruneOldEventsWorker do
  describe '#perform' do
    let(:user) { create(:user) }

    let!(:expired_event) { create(:event, :closed, author: user, created_at: 25.months.ago) }
    let!(:not_expired_event) { create(:event, :closed, author: user,  created_at: 1.day.ago) }
    let!(:exactly_2_years_event) { create(:event, :closed, author: user, created_at: 2.years.ago) }

    it 'prunes events older than 2 years' do
      expect { subject.perform }.to change { Event.count }.by(-1)
      expect(Event.find_by(id: expired_event.id)).to be_nil
    end

    it 'leaves fresh events' do
      subject.perform
      expect(not_expired_event.reload).to be_present
    end

    it 'leaves events from exactly 12 months ago' do
      subject.perform
      expect(exactly_12_months_event).to be_present
    end
  end
end
