# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::LinkedResources, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:zoom_meeting) { create(:zoom_meeting, issue: work_item) }

  describe '#zoom_meetings' do
    subject { described_class.new(work_item).zoom_meetings }

    context 'when zoom meeting is added' do
      it { is_expected.to eq(work_item.zoom_meetings.added_to_issue) }
      it { is_expected.to include(zoom_meeting) }
    end

    context 'when zoom meeting is removed' do
      before do
        zoom_meeting.update!(issue_status: :removed)
      end

      it { is_expected.not_to include(zoom_meeting) }
    end
  end
end
