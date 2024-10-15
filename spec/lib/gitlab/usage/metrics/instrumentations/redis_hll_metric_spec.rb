# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::RedisHLLMetric, :clean_gitlab_redis_shared_state,
  feature_category: :service_ping do
  before do
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 1, time: 1.week.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 1, time: 2.weeks.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 2, time: 2.weeks.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 2, time: 2.months.ago)
  end

  context 'for 28d' do
    let(:expected_value) { 2 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', options: { events: ['i_quickactions_approve'] } }
  end

  context 'for 7d' do
    let(:expected_value) { 1 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '7d', options: { events: ['i_quickactions_approve'] } }
  end

  it 'raise exception if events options is not present' do
    expect { described_class.new(time_frame: '28d') }.to raise_error(ArgumentError)
  end

  context "with events attribute defined" do
    let(:expected_value) { 2 }

    before do
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:g_project_management_issue_iteration_changed, values: 1, time: 1.week.ago, property_name: 'user')
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:g_project_management_issue_iteration_changed, values: 2, time: 2.weeks.ago, property_name: 'user')
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:g_project_management_issue_iteration_changed, values: 1, time: 2.weeks.ago, property_name: 'user')
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:g_project_management_issue_iteration_changed, values: 3, time: 2.weeks.ago, property_name: 'project')
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:g_project_management_issue_iteration_changed, values: 3, time: 2.weeks.ago, property_name: 'label')
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', events: [name: 'g_project_management_issue_iteration_changed', unique: 'user.id'] }

    context "with events having different `unique` values" do
      let(:expected_value) { 3 }
      let(:flag_enabled) { false }
      let(:events) do
        [
          { name: 'g_project_management_issue_iteration_changed', unique: 'user.id' },
          { name: 'g_project_management_issue_label_changed', unique: 'project.id' }
        ]
      end

      it 'raises an exception' do
        expect do
          described_class.new(time_frame: '28d', events: events).value
        end.to raise_error(Gitlab::Usage::MetricDefinition::InvalidError)
      end
    end

    context "with options attributes also defined" do
      it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', options: { events: ['i_quickactions_approve'] }, events: [name: 'g_project_management_issue_iteration_changed', unique: 'user.id'] }
    end

    context 'with property_name excluding ".id"' do
      let(:expected_value) { 1 }

      it_behaves_like 'a correct instrumented metric value',
        { time_frame: '28d', events: [name: 'g_project_management_issue_iteration_changed', unique: 'label'] }
    end
  end

  describe 'children classes' do
    let(:options) { { events: ['i_quickactions_approve'] } }

    context 'availability not defined' do
      subject { Class.new(described_class).new(time_frame: nil, options: options) }

      it 'returns default availability' do
        expect(subject.available?).to eq(true)
      end
    end

    context 'availability defined' do
      subject do
        Class.new(described_class) do
          available? { false }
        end.new(time_frame: nil, options: options)
      end

      it 'returns defined availability' do
        expect(subject.available?).to eq(false)
      end
    end
  end
end
