# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateMergeScheduleService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }

  let(:service) { described_class.new(merge_request, merge_after: merge_after) }

  subject(:execute) { service.execute }

  describe '#execute' do
    context 'when passing a merge_after date' do
      let(:merge_after) { '2024-11-07T19:17+0200' }

      specify do
        expect { execute }.to change { merge_request.reload.merge_schedule&.merge_after }
          .to(Time.zone.parse(merge_after).in_time_zone('Etc/UTC'))
      end

      it { expect { execute }.to change { MergeRequests::MergeSchedule.count }.by(1) }
    end

    context 'when passing nil for merge_after' do
      let(:merge_after) { nil }

      context 'when merge_schedule exists' do
        before do
          merge_request.create_merge_schedule(merge_after: '2024-11-07T19:17+0200')
        end

        it { expect { execute }.to change { merge_request.reload.merge_schedule&.merge_after }.to(nil) }
        it { expect { execute }.to change { MergeRequests::MergeSchedule.count }.by(-1) }
      end

      context 'when merge_schedule does not exist' do
        it { expect { execute }.not_to change { merge_request.reload.merge_schedule } }
        it { expect { execute }.not_to change { MergeRequests::MergeSchedule.count } }
      end
    end
  end
end
