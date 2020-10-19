# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::PruneOldAnnotationsWorker do
  let_it_be(:now) { DateTime.parse('2020-06-02T00:12:00Z') }
  let_it_be(:two_weeks_old_annotation) { create(:metrics_dashboard_annotation, starting_at: now.advance(weeks: -2)) }
  let_it_be(:one_day_old_annotation) { create(:metrics_dashboard_annotation, starting_at: now.advance(days: -1)) }
  let_it_be(:month_old_annotation) { create(:metrics_dashboard_annotation, starting_at: now.advance(months: -1)) }

  describe '#perform' do
    it 'removes all annotations older than cut off', :aggregate_failures do
      Timecop.freeze(now) do
        described_class.new.perform

        expect(Metrics::Dashboard::Annotation.all).to match_array([one_day_old_annotation, two_weeks_old_annotation])

        # is idempotent in the scope of 24h
        expect { described_class.new.perform }.not_to change { Metrics::Dashboard::Annotation.all.to_a }
        travel_to(24.hours.from_now) do
          described_class.new.perform
          expect(Metrics::Dashboard::Annotation.all).to match_array([one_day_old_annotation])
        end
      end
    end

    context 'batch to be deleted is bigger than upper limit' do
      it 'schedules second job to clear remaining records' do
        Timecop.freeze(now) do
          create(:metrics_dashboard_annotation, starting_at: 1.month.ago)
          stub_const("#{described_class}::DELETE_LIMIT", 1)

          expect(described_class).to receive(:perform_async)

          described_class.new.perform
        end
      end
    end
  end
end
