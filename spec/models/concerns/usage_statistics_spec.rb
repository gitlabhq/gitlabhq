# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsageStatistics do
  describe '.distinct_count_by' do
    let_it_be(:issue_1) { create(:issue) }
    let_it_be(:issue_2) { create(:issue) }

    context 'two records created by the same issue' do
      let!(:models_created_by_issue) do
        create(:zoom_meeting, :added_to_issue, issue: issue_1)
        create(:zoom_meeting, :removed_from_issue, issue: issue_1)
      end

      it 'returns a count of 1' do
        expect(::ZoomMeeting.distinct_count_by(:issue_id)).to eq(1)
      end

      context 'when given no column to count' do
        it 'counts by :id and returns a count of 2' do
          expect(::ZoomMeeting.distinct_count_by).to eq(2)
        end
      end
    end

    context 'one record created by each issue' do
      let!(:model_created_by_issue_1) { create(:zoom_meeting, issue: issue_1) }
      let!(:model_created_by_issue_2) { create(:zoom_meeting, issue: issue_2) }

      it 'returns a count of 2' do
        expect(::ZoomMeeting.distinct_count_by(:issue_id)).to eq(2)
      end
    end

    context 'the count query times out' do
      before do
        allow_next_instance_of(ActiveRecord::Relation) do |instance|
          allow(instance).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))
        end
      end

      it 'does not raise an error' do
        expect { ::ZoomMeeting.distinct_count_by(:issue_id) }.not_to raise_error
      end

      it 'returns -1' do
        expect(::ZoomMeeting.distinct_count_by(:issue_id)).to eq(-1)
      end
    end
  end
end
