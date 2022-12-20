# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents, feature_category: :value_stream_management do
  describe '#selectable_events' do
    subject(:selectable_events) { described_class.selectable_events }

    it 'excludes internal events' do
      expect(selectable_events).to include(Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated)
      expect(selectable_events).to exclude(Gitlab::Analytics::CycleAnalytics::StageEvents::IssueStageEnd)
    end
  end
end
