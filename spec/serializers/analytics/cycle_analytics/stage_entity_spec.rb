# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageEntity do
  let(:stage) { build(:cycle_analytics_project_stage, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }

  subject(:entity_json) { described_class.new(Analytics::CycleAnalytics::StagePresenter.new(stage)).as_json }

  it 'exposes start and end event descriptions' do
    expect(entity_json).to have_key(:start_event_html_description)
    expect(entity_json).to have_key(:end_event_html_description)
  end
end
