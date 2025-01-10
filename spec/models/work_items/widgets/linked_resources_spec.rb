# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::LinkedResources, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:zoom_meeting) { create(:zoom_meeting, issue: work_item) }

  describe '#zoom_meetings' do
    subject { described_class.new(work_item).zoom_meetings }

    it { is_expected.to eq(work_item.zoom_meetings) }
  end
end
