require 'rails_helper'

describe Gitlab::BackgroundMigration::PopulateMergeRequestMetricsWithEventsData, :migration, schema: 20171128214150 do
  # commits_count attribute is added in a next migration
  before do
    allow_any_instance_of(MergeRequestDiff)
      .to receive(:commits_count=).and_return(nil)
  end

  describe '#perform' do
    let(:mr_with_event) { create(:merge_request) }
    let!(:merged_event) { create(:event, :merged, target: mr_with_event) }
    let!(:closed_event) { create(:event, :closed, target: mr_with_event) }

    before do
      # Make sure no metrics are created and kept through after_* callbacks.
      mr_with_event.metrics.destroy!
    end

    it 'inserts metrics and updates closed and merged events' do
      subject.perform(mr_with_event.id, mr_with_event.id)

      mr_with_event.reload

      expect(mr_with_event.metrics).to have_attributes(latest_closed_by_id: closed_event.author_id,
                                                       merged_by_id: merged_event.author_id)
      expect(mr_with_event.metrics.latest_closed_at.to_s).to eq(closed_event.updated_at.to_s)
    end
  end

  describe '#insert_metrics_for_range' do
    let!(:mrs_without_metrics) { create_list(:merge_request, 3) }
    let!(:mrs_with_metrics) { create_list(:merge_request, 2) }

    before do
      # Make sure no metrics are created and kept through after_* callbacks.
      mrs_without_metrics.each { |m| m.metrics.destroy! }
    end

    it 'inserts merge_request_metrics for merge_requests without one' do
      expect { subject.insert_metrics_for_range(MergeRequest.first.id, MergeRequest.last.id) }
        .to change(MergeRequest::Metrics, :count).from(2).to(5)

      mrs_without_metrics.each do |mr_without_metrics|
        expect(mr_without_metrics.reload.metrics).to be_present
      end
    end

    it 'does not inserts merge_request_metrics for MRs out of given range' do
      expect { subject.insert_metrics_for_range(mrs_with_metrics.first.id, mrs_with_metrics.last.id) }
        .not_to change(MergeRequest::Metrics, :count).from(2)
    end
  end

  describe '#update_metrics_with_events_data' do
    context 'closed events data update' do
      let(:users) { create_list(:user, 3) }
      let(:mrs_with_event) { create_list(:merge_request, 3) }

      before do
        create_list(:event, 2, :closed, author: users.first, target: mrs_with_event.first)
        create_list(:event, 3, :closed, author: users.second, target: mrs_with_event.second)
        create(:event, :closed, author: users.third, target: mrs_with_event.third)
      end

      it 'migrates multiple MR metrics with closed event data' do
        mr_without_event = create(:merge_request)
        create(:event, :merged)

        subject.update_metrics_with_events_data(mrs_with_event.first.id, mrs_with_event.last.id)

        mrs_with_event.each do |mr_with_event|
          latest_event = Event.where(action: 3, target: mr_with_event).last

          mr_with_event.metrics.reload

          expect(mr_with_event.metrics.latest_closed_by).to eq(latest_event.author)
          expect(mr_with_event.metrics.latest_closed_at.to_s).to eq(latest_event.updated_at.to_s)
        end

        expect(mr_without_event.metrics.reload).to have_attributes(latest_closed_by_id: nil,
                                                                   latest_closed_at: nil)
      end

      it 'does not updates metrics out of given range' do
        out_of_range_mr = create(:merge_request)
        create(:event, :closed, author: users.last, target: out_of_range_mr)

        expect { subject.perform(mrs_with_event.first.id, mrs_with_event.second.id) }
          .not_to change { out_of_range_mr.metrics.reload.merged_by }
          .from(nil)
      end
    end

    context 'merged events data update' do
      let(:users) { create_list(:user, 3) }
      let(:mrs_with_event) { create_list(:merge_request, 3) }

      before do
        create_list(:event, 2, :merged, author: users.first, target: mrs_with_event.first)
        create_list(:event, 3, :merged, author: users.second, target: mrs_with_event.second)
        create(:event, :merged, author: users.third, target: mrs_with_event.third)
      end

      it 'migrates multiple MR metrics with merged event data' do
        mr_without_event = create(:merge_request)
        create(:event, :merged)

        subject.update_metrics_with_events_data(mrs_with_event.first.id, mrs_with_event.last.id)

        mrs_with_event.each do |mr_with_event|
          latest_event = Event.where(action: Event::MERGED, target: mr_with_event).last

          expect(mr_with_event.metrics.reload.merged_by).to eq(latest_event.author)
        end

        expect(mr_without_event.metrics.reload).to have_attributes(merged_by_id: nil)
      end

      it 'does not updates metrics out of given range' do
        out_of_range_mr = create(:merge_request)
        create(:event, :merged, author: users.last, target: out_of_range_mr)

        expect { subject.perform(mrs_with_event.first.id, mrs_with_event.second.id) }
          .not_to change { out_of_range_mr.metrics.reload.merged_by }
          .from(nil)
      end
    end
  end
end
