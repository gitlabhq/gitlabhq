# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProductAnalyticsEvent, type: :model do
  it { is_expected.to belong_to(:project) }
  it { expect(described_class).to respond_to(:order_by_time) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:event_id) }
    it { is_expected.to validate_presence_of(:v_collector) }
    it { is_expected.to validate_presence_of(:v_etl) }
  end

  describe '.timerange' do
    let_it_be(:event_1) { create(:product_analytics_event, collector_tstamp: Time.zone.now - 1.day) }
    let_it_be(:event_2) { create(:product_analytics_event, collector_tstamp: Time.zone.now - 5.days) }
    let_it_be(:event_3) { create(:product_analytics_event, collector_tstamp: Time.zone.now - 15.days) }

    it { expect(described_class.timerange(3.days)).to match_array([event_1]) }
    it { expect(described_class.timerange(7.days)).to match_array([event_1, event_2]) }
    it { expect(described_class.timerange(30.days)).to match_array([event_1, event_2, event_3]) }
  end

  describe '.count_by_graph' do
    let_it_be(:events) do
      [
        create(:product_analytics_event, platform: 'web'),
        create(:product_analytics_event, platform: 'web'),
        create(:product_analytics_event, platform: 'app'),
        create(:product_analytics_event, platform: 'mobile', collector_tstamp: Time.zone.now - 10.days)
      ]
    end

    it { expect(described_class.count_by_graph('platform', 7.days)).to eq({ 'app' => 1, 'web' => 2 }) }
    it { expect(described_class.count_by_graph('platform', 30.days)).to eq({ 'app' => 1, 'mobile' => 1, 'web' => 2 }) }
  end

  describe '.by_category_and_action' do
    let_it_be(:event) { create(:product_analytics_event, se_category: 'catA', se_action: 'actA') }

    before do
      create(:product_analytics_event, se_category: 'catA', se_action: 'actB')
      create(:product_analytics_event, se_category: 'catB', se_action: 'actA')
    end

    it { expect(described_class.by_category_and_action('catA', 'actA')).to match_array([event]) }
  end

  describe '.count_collector_tstamp_by_day' do
    let_it_be(:time_now) { Time.zone.now }
    let_it_be(:time_ago) { Time.zone.now - 5.days }

    let_it_be(:events) do
      create_list(:product_analytics_event, 3, collector_tstamp: time_now) +
        create_list(:product_analytics_event, 2, collector_tstamp: time_ago)
    end

    subject { described_class.count_collector_tstamp_by_day(7.days) }

    it { is_expected.to eq({ time_now.beginning_of_day => 3, time_ago.beginning_of_day => 2 }) }
  end
end
