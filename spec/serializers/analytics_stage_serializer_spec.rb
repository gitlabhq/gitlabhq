require 'spec_helper'

describe AnalyticsStageSerializer do
  subject do
    described_class.new.represent(resource)
  end

  let(:resource) do
    Gitlab::CycleAnalytics::CodeStage.new(options: { project: double })
  end

  before do
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:project_median).and_return(1.12)
    allow_any_instance_of(Gitlab::CycleAnalytics::BaseEventFetcher).to receive(:event_result).and_return({})
  end

  it 'generates payload for single object' do
    expect(subject).to be_kind_of Hash
  end

  it 'contains important elements of AnalyticsStage' do
    expect(subject).to include(:title, :description, :value)
  end

  context 'when median is equal 0' do
    before do
      allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:project_median).and_return(0)
    end

    it 'sets the value to nil' do
      expect(subject.fetch(:value)).to be_nil
    end
  end

  context 'when median is below 1' do
    before do
      allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:project_median).and_return(0.12)
    end

    it 'sets the value to equal to median' do
      expect(subject.fetch(:value)).to eq('less than a minute')
    end
  end

  context 'when median is above 1' do
    before do
      allow_any_instance_of(Gitlab::CycleAnalytics::BaseStage).to receive(:project_median).and_return(60.12)
    end

    it 'sets the value to equal to median' do
      expect(subject.fetch(:value)).to eq('1 minute')
    end
  end
end
