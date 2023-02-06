# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageEntity do
  let(:stage) { build(:cycle_analytics_stage, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }

  subject(:entity_json) { described_class.new(Analytics::CycleAnalytics::StagePresenter.new(stage)).as_json }

  it 'exposes start and end event descriptions' do
    expect(entity_json).to have_key(:start_event_html_description)
    expect(entity_json).to have_key(:end_event_html_description)
  end

  it 'exposes start_event and end_event objects' do
    expect(entity_json[:start_event][:identifier]).to eq(entity_json[:start_event_identifier])
    expect(entity_json[:end_event][:identifier]).to eq(entity_json[:end_event_identifier])

    expect(entity_json[:start_event][:html_description]).to eq(entity_json[:start_event_html_description])
    expect(entity_json[:end_event][:html_description]).to eq(entity_json[:end_event_html_description])
  end
end
