# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PruneOldEventsWorker, feature_category: :user_profile do
  describe '#perform' do
    let(:user) { create(:user) }

    let!(:expired_event) { create(:event, :closed, author: user, created_at: 37.months.ago) }
    let!(:not_expired_1_day_event) { create(:event, :closed, author: user, created_at: 1.day.ago) }
    let!(:not_expired_13_month_event) { create(:event, :closed, author: user, created_at: 13.months.ago) }
    let!(:not_expired_3_years_event) { create(:event, :closed, author: user, created_at: 3.years.ago) }

    it 'prunes events older than 3 years' do
      expect { subject.perform }.to change { Event.count }.by(-1)
      expect(Event.find_by(id: expired_event.id)).to be_nil
    end

    it 'leaves fresh events' do
      subject.perform
      expect(not_expired_1_day_event.reload).to be_present
    end

    it 'leaves events from 13 months ago' do
      subject.perform
      expect(not_expired_13_month_event.reload).to be_present
    end

    it 'leaves events from 3 years ago' do
      subject.perform
      expect(not_expired_3_years_event).to be_present
    end

    context 'with ops_prune_old_events FF disabled' do
      before do
        stub_feature_flags(ops_prune_old_events: false)
      end

      it 'does not delete' do
        subject.perform

        expect(Event.find_by(id: expired_event.id)).to be_present
      end
    end
  end

  describe '.pruning_enabled?' do
    subject(:pruning_enabled) { described_class.pruning_enabled? }

    it { is_expected.to be(true) }

    context 'with ops_prune_old_events FF disabled' do
      before do
        stub_feature_flags(ops_prune_old_events: false)
      end

      it { is_expected.to be(false) }
    end
  end
end
