# frozen_string_literal: true

require 'spec_helper'

shared_examples 'base stage' do
  ISSUES_MEDIAN = 30.minutes.to_i

  let(:stage) { described_class.new(options: { project: double }) }

  before do
    allow(stage).to receive(:project_median).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEventFetcher).to receive(:event_result).and_return({})
  end

  it 'has the median data value' do
    expect(stage.as_json[:value]).not_to be_nil
  end

  it 'has the median data stage' do
    expect(stage.as_json[:title]).not_to be_nil
  end

  it 'has the median data description' do
    expect(stage.as_json[:description]).not_to be_nil
  end

  it 'has the title' do
    expect(stage.title).to eq(stage_name.to_s.capitalize)
  end

  it 'has the events' do
    expect(stage.events).not_to be_nil
  end
end

shared_examples 'calculate #median with date range' do
  context 'when valid date range is given' do
    before do
      stage_options[:from] = 5.days.ago
      stage_options[:to] = 5.days.from_now
    end

    it { expect(stage.project_median).to eq(ISSUES_MEDIAN) }
  end

  context 'when records are out of the date range' do
    before do
      stage_options[:from] = 2.years.ago
      stage_options[:to] = 1.year.ago
    end

    it { expect(stage.project_median).to eq(nil) }
  end
end
